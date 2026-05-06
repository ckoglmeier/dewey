#!/usr/bin/env bash
# Classroom ↔ Codex skill sync
#
# Mirrors Classroom skills into ~/.codex/skills/ so OpenAI Codex picks them up
# alongside Claude Code. SKILL.md format is identical between the two agents —
# no translation needed. Uses symlinks so Classroom cache refreshes propagate
# automatically without re-running the sync.
#
# Usage:
#   classroom-sync-codex.sh             # sync skills, print summary
#   classroom-sync-codex.sh --status    # show sync state, no changes
#   classroom-sync-codex.sh --agents-md [DIR]  # write AGENTS.md to DIR (default: .)
#   classroom-sync-codex.sh --dry-run   # print what would change, no writes
#   classroom-sync-codex.sh --remove    # remove all Classroom symlinks from ~/.codex/skills/
#
# Env vars honoured:
#   CLASSROOM_DIR    Where the Classroom cache lives (default: ~/.claude/classroom)
#   CODEX_HOME       Where Codex stores its config (default: ~/.codex)
#
# Requires: bash 3.2+, find, ln, mkdir, python3 (for --agents-md only)

set -euo pipefail

CLASSROOM_DIR="${CLASSROOM_DIR:-$HOME/.claude/classroom}"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
CODEX_SKILLS_DIR="$CODEX_HOME/skills"
CODEX_CONTEXT_DIR="$CODEX_HOME/context"

DRY_RUN=0
STATUS_ONLY=0
AGENTS_MD=0
AGENTS_MD_DIR="."
REMOVE=0

# ---- Helpers ----------------------------------------------------------------
green()  { printf "\033[1;32m%s\033[0m" "$*"; }
yellow() { printf "\033[1;33m%s\033[0m" "$*"; }
red()    { printf "\033[1;31m%s\033[0m" "$*"; }
say()    { printf "\033[1;36m▸\033[0m %s\n" "$*"; }
note()   { printf "  %s\n" "$*"; }

# ---- Argument parsing -------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --status)    STATUS_ONLY=1; shift ;;
    --agents-md) AGENTS_MD=1; [[ $# -gt 1 && "${2:-}" != --* ]] && { AGENTS_MD_DIR="$2"; shift; }; shift ;;
    --dry-run)   DRY_RUN=1; shift ;;
    --remove)    REMOVE=1; shift ;;
    *) printf "Unknown argument: %s\n" "$1" >&2; exit 1 ;;
  esac
done

# ---- Pre-flight -------------------------------------------------------------
if [[ ! -d "$CLASSROOM_DIR" ]]; then
  printf "Classroom cache not found at %s\n" "$CLASSROOM_DIR" >&2
  printf "Run the Classroom installer first.\n" >&2
  exit 1
fi

if [[ ! -d "$CODEX_HOME" ]] && ! command -v codex >/dev/null 2>&1; then
  printf "Codex not detected (~/.codex/ missing, 'codex' not on PATH).\n" >&2
  printf "Install Codex first: https://github.com/openai/codex\n" >&2
  exit 1
fi

# ---- list_skills: print "skill_name|source_path" pairs ---------------------
# One line per skill. Avoids associative arrays for bash 3.2 compatibility.
list_skills() {
  # Plugins in the Classroom cache
  while IFS= read -r skill_md; do
    skill_name="$(basename "$(dirname "$skill_md")")"
    printf "%s|%s\n" "$skill_name" "$skill_md"
  done < <(find "$CLASSROOM_DIR/plugins" -path "*/skills/*/SKILL.md" 2>/dev/null | sort)

  # Guide skill
  if [[ -f "$CLASSROOM_DIR/guide/SKILL.md" ]]; then
    printf "classroom|%s\n" "$CLASSROOM_DIR/guide/SKILL.md"
  fi
}

# ---- list_context_dirs: print "<plugin>|<source_dir>" pairs -----------------
# Each plugin's whole context/ directory is one symlink unit.
list_context_dirs() {
  while IFS= read -r ctx_dir; do
    [[ -d "$ctx_dir" ]] || continue
    plugin_name="$(basename "$(dirname "$ctx_dir")")"
    printf "%s|%s\n" "$plugin_name" "$ctx_dir"
  done < <(find "$CLASSROOM_DIR/plugins" -mindepth 2 -maxdepth 2 -type d -name context 2>/dev/null | sort)
}

# Verify we have at least one skill
skill_count=0
while IFS='|' read -r _name _path; do
  skill_count=$((skill_count + 1))
done < <(list_skills)

if [[ "$skill_count" -eq 0 ]]; then
  printf "No skills found in Classroom cache at %s\n" "$CLASSROOM_DIR" >&2
  exit 1
fi

# ---- Remove mode ------------------------------------------------------------
if [[ "$REMOVE" -eq 1 ]]; then
  say "Removing Classroom symlinks from $CODEX_SKILLS_DIR and $CODEX_CONTEXT_DIR"
  removed=0
  while IFS='|' read -r skill_name src; do
    target="$CODEX_SKILLS_DIR/$skill_name/SKILL.md"
    if [[ -L "$target" ]]; then
      if [[ "$DRY_RUN" -eq 1 ]]; then
        note "[dry-run] Would remove symlink: $target"
      else
        rm -f "$target"
        rmdir "$CODEX_SKILLS_DIR/$skill_name" 2>/dev/null || true
      fi
      removed=$((removed + 1))
    fi
  done < <(list_skills)
  while IFS='|' read -r plugin_name src; do
    target="$CODEX_CONTEXT_DIR/$plugin_name"
    if [[ -L "$target" ]]; then
      if [[ "$DRY_RUN" -eq 1 ]]; then
        note "[dry-run] Would remove context symlink: $target"
      else
        rm -f "$target"
      fi
      removed=$((removed + 1))
    fi
  done < <(list_context_dirs)
  # Try to remove the context dir if it's empty
  [[ "$DRY_RUN" -eq 0 ]] && rmdir "$CODEX_CONTEXT_DIR" 2>/dev/null || true
  [[ "$DRY_RUN" -eq 0 ]] && say "Removed $removed Classroom symlink(s) from Codex."
  [[ "$DRY_RUN" -eq 1 ]] && say "[dry-run] Would remove $removed symlink(s)."
  exit 0
fi

# ---- Status / Sync ----------------------------------------------------------
synced=0
stale=0
missing=0

while IFS='|' read -r skill_name src; do
  skill_dir="$CODEX_SKILLS_DIR/$skill_name"
  target="$skill_dir/SKILL.md"

  if [[ -L "$target" && "$(readlink "$target")" == "$src" ]]; then
    synced=$((synced + 1))
    if [[ "$STATUS_ONLY" -eq 1 ]]; then
      printf "  %s %-40s → %s\n" "$(green ✓)" "$skill_name" "$src"
    fi

  elif [[ -L "$target" ]]; then
    # Symlink points elsewhere (stale / source moved after refresh)
    stale=$((stale + 1))
    if [[ "$STATUS_ONLY" -eq 1 ]]; then
      printf "  %s %-40s (stale symlink → %s)\n" "$(yellow ●)" "$skill_name" "$(readlink "$target")"
    elif [[ "$DRY_RUN" -eq 0 ]]; then
      ln -sf "$src" "$target"
      synced=$((synced + 1))
    fi

  elif [[ -f "$target" ]]; then
    # Regular file — don't clobber a non-Classroom file
    stale=$((stale + 1))
    if [[ "$STATUS_ONLY" -eq 1 ]]; then
      printf "  %s %-40s (existing file, not managed by Classroom)\n" "$(yellow ●)" "$skill_name"
    elif [[ "$DRY_RUN" -eq 1 ]]; then
      printf "  %s %-40s (would skip — existing non-symlink file)\n" "$(yellow ●)" "$skill_name"
    fi

  else
    # Not yet in Codex
    missing=$((missing + 1))
    if [[ "$STATUS_ONLY" -eq 1 ]]; then
      printf "  %s %-40s (not in Codex yet)\n" "$(red ✗)" "$skill_name"
    elif [[ "$DRY_RUN" -eq 1 ]]; then
      printf "  %s %-40s → %s\n" "$(green +)" "$skill_name" "$src"
    else
      mkdir -p "$skill_dir"
      ln -sf "$src" "$target"
      synced=$((synced + 1))
    fi
  fi
done < <(list_skills)

# ---- Context sync -----------------------------------------------------------
ctx_synced=0
ctx_stale=0
ctx_missing=0
while IFS='|' read -r plugin_name src; do
  target="$CODEX_CONTEXT_DIR/$plugin_name"

  if [[ -L "$target" && "$(readlink "$target")" == "$src" ]]; then
    ctx_synced=$((ctx_synced + 1))
    if [[ "$STATUS_ONLY" -eq 1 ]]; then
      printf "  %s %-40s → %s\n" "$(green ✓)" "context/$plugin_name" "$src"
    fi
  elif [[ -L "$target" ]]; then
    ctx_stale=$((ctx_stale + 1))
    if [[ "$STATUS_ONLY" -eq 1 ]]; then
      printf "  %s %-40s (stale context symlink → %s)\n" "$(yellow ●)" "context/$plugin_name" "$(readlink "$target")"
    elif [[ "$DRY_RUN" -eq 0 ]]; then
      ln -sfn "$src" "$target"
      ctx_synced=$((ctx_synced + 1))
    fi
  elif [[ -e "$target" ]]; then
    ctx_stale=$((ctx_stale + 1))
    if [[ "$STATUS_ONLY" -eq 1 ]]; then
      printf "  %s %-40s (existing path, not managed by Classroom)\n" "$(yellow ●)" "context/$plugin_name"
    elif [[ "$DRY_RUN" -eq 1 ]]; then
      printf "  %s %-40s (would skip — existing non-symlink)\n" "$(yellow ●)" "context/$plugin_name"
    fi
  else
    ctx_missing=$((ctx_missing + 1))
    if [[ "$STATUS_ONLY" -eq 1 ]]; then
      printf "  %s %-40s (not in Codex yet)\n" "$(red ✗)" "context/$plugin_name"
    elif [[ "$DRY_RUN" -eq 1 ]]; then
      printf "  %s %-40s → %s\n" "$(green +)" "context/$plugin_name" "$src"
    else
      mkdir -p "$CODEX_CONTEXT_DIR"
      ln -sfn "$src" "$target"
      ctx_synced=$((ctx_synced + 1))
    fi
  fi
done < <(list_context_dirs)

if [[ "$STATUS_ONLY" -eq 1 ]]; then
  echo
  printf "  Skills:   synced %d, stale %d, missing %d\n" "$synced" "$stale" "$missing"
  printf "  Context:  synced %d, stale %d, missing %d\n" "$ctx_synced" "$ctx_stale" "$ctx_missing"
  printf "  Codex skills dir:  %s\n" "$CODEX_SKILLS_DIR"
  printf "  Codex context dir: %s\n" "$CODEX_CONTEXT_DIR"
  [[ "$missing" -gt 0 || "$ctx_missing" -gt 0 ]] && printf "  Run without --status to sync missing items.\n"
  exit 0
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo
  say "[dry-run] Would sync $((synced + missing)) skill(s) to $CODEX_SKILLS_DIR"
  say "[dry-run] Would sync $((ctx_synced + ctx_missing)) context bundle(s) to $CODEX_CONTEXT_DIR"
  exit 0
fi

# ---- AGENTS.md generation ---------------------------------------------------
if [[ "$AGENTS_MD" -eq 1 ]]; then
  agents_file="$AGENTS_MD_DIR/AGENTS.md"
  say "Generating $agents_file"

  {
    printf "# Classroom Skills\n\n"
    printf "This project has access to skills from the [Classroom](https://github.com/ckoglmeier/classroom) marketplace.\n"
    printf "The following skills are available in your Codex environment:\n\n"

    while IFS='|' read -r skill_name src; do
      desc=""
      if [[ -f "$src" ]] && command -v python3 >/dev/null 2>&1; then
        desc="$(python3 - "$src" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
m = re.match(r'^---\n(.*?)\n---\n', text, re.DOTALL)
if m:
    for line in m.group(1).splitlines():
        if line.startswith('description:'):
            print(line.split(':', 1)[1].strip().strip('"').strip("'"))
            break
PY
)"
      fi
      if [[ -n "$desc" ]]; then
        printf '%s\n' "- \`/$skill_name\` — $desc"
      else
        printf '%s\n' "- \`/$skill_name\`"
      fi
    done < <(list_skills)

    printf "\n## Using skills\n\n"
    printf "Invoke a skill in your Codex prompt:\n\n"
    printf "\`\`\`\n"
    printf "/meeting-prep for tomorrow's product review\n"
    printf "/competitive-analysis on Acme Corp's latest pricing\n"
    printf "\`\`\`\n\n"
    printf "To install more skills (Claude Code): \`/classroom install\`\n"
  } > "$agents_file"

  note "Written: $agents_file"
fi

# ---- Summary ----------------------------------------------------------------
new_count=$((skill_count - synced - stale))
if [[ "$new_count" -gt 0 || "$stale" -gt 0 ]]; then
  say "Synced $synced skill(s) to Codex ($new_count new, $stale updated)"
else
  say "Codex skills already up to date ($synced skill(s))"
fi
note "Codex skills dir:  $CODEX_SKILLS_DIR"
if [[ "$ctx_synced" -gt 0 || "$ctx_missing" -gt 0 ]]; then
  say "Synced $ctx_synced context bundle(s)"
  note "Codex context dir: $CODEX_CONTEXT_DIR"
fi
