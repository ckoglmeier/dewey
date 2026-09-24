#!/usr/bin/env bash
# Dewey ↔ Codex sync
#
# Makes Dewey's plugins and the Guide available in OpenAI Codex.
#
# Two modes (DEWEY_CODEX_MODE=auto|plugin|symlink, default auto):
#
#   plugin   Codex 0.149+ ships a native plugin marketplace that reads Dewey's
#            manifests directly. The Dewey cache is registered as a Codex
#            marketplace and every in-tree plugin is installed with
#            `codex plugin add <plugin>@<marketplace>`. Re-running the sync
#            re-copies each plugin from the cache, so Dewey refreshes reach
#            Codex on the next sync (the refresh script runs it for you).
#
#   symlink  Fallback for Codex builds without `codex plugin`: every skill
#            directory is symlinked into ~/.agents/skills/<skill>, the documented
#            Codex user-skills location. Codex follows symlinked skill
#            *directories*; it never discovers symlinked SKILL.md *files*, which
#            is why the pre-2.3 per-file mirror stopped working.
#
# In both modes the Guide is linked as ~/.agents/skills/dewey, and leftovers from
# Dewey <= 2.2 are removed: ~/.codex/skills/<name>/SKILL.md file symlinks and
# ~/.codex/context/<plugin> mirrors (not a Codex concept — skills read the
# canonical context from ~/.claude/dewey/... directly).
#
# Codex invokes skills with `$`, not `/`: type `$` and pick from the list.
#
# Usage:
#   dewey-sync-codex.sh             # sync, print summary
#   dewey-sync-codex.sh --status    # show sync state, no changes
#   dewey-sync-codex.sh --dry-run   # print what would change, no writes
#   dewey-sync-codex.sh --remove    # unregister/unlink everything Dewey put in Codex
#   dewey-sync-codex.sh --agents-md # deprecated no-op (Codex lists skills itself)
#
# Env vars honoured:
#   DEWEY_DIR                Dewey cache (default: ~/.claude/dewey)
#   CODEX_HOME               Codex config dir (default: ~/.codex)
#   DEWEY_AGENTS_SKILLS_DIR  Codex user skills dir (default: ~/.agents/skills)
#   DEWEY_CODEX_MODE         auto | plugin | symlink (default: auto)
#   DEWEY_CODEX_DETECTED     Test override: auto | 1 | 0 (default: auto)
#
# Requires: bash 3.2+, find, ln, mkdir, readlink; python3 (marketplace parsing);
#           the `codex` CLI for plugin mode.

set -euo pipefail

DEWEY_DIR="${DEWEY_DIR:-$HOME/.claude/dewey}"
DEWEY_DIR="${DEWEY_DIR%/}"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
CODEX_HOME="${CODEX_HOME%/}"
AGENTS_SKILLS_DIR="${DEWEY_AGENTS_SKILLS_DIR:-$HOME/.agents/skills}"
AGENTS_SKILLS_DIR="${AGENTS_SKILLS_DIR%/}"
DEWEY_CODEX_MODE="${DEWEY_CODEX_MODE:-auto}"
DEWEY_CODEX_DETECTED="${DEWEY_CODEX_DETECTED:-auto}"

LEGACY_SKILLS_DIR="$CODEX_HOME/skills"
LEGACY_CONTEXT_DIR="$CODEX_HOME/context"
GUIDE_DIR="$DEWEY_DIR/guide"
GUIDE_LINK="$AGENTS_SKILLS_DIR/dewey"

DRY_RUN=0
STATUS_ONLY=0
REMOVE=0
AGENTS_MD=0

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
    --dry-run)   DRY_RUN=1; shift ;;
    --remove)    REMOVE=1; shift ;;
    --agents-md) AGENTS_MD=1; [[ $# -gt 1 && "${2:-}" != --* ]] && shift; shift ;;
    *) printf "Unknown argument: %s\n" "$1" >&2; exit 1 ;;
  esac
done

if [[ "$AGENTS_MD" -eq 1 ]]; then
  say "AGENTS.md generation was removed in Dewey 2.3."
  note "Codex builds its own skills catalog from the installed plugins and skills, so"
  note "listing them in AGENTS.md is redundant (and used the wrong '/name' syntax —"
  note "Codex invokes skills with '\$name'). Nothing was written."
  exit 0
fi

# ---- Pre-flight -------------------------------------------------------------
if [[ ! -d "$DEWEY_DIR" ]]; then
  printf "Dewey cache not found at %s\n" "$DEWEY_DIR" >&2
  printf "Run the Dewey installer first.\n" >&2
  exit 1
fi

case "$DEWEY_CODEX_DETECTED" in
  auto)
    CODEX_DETECTED=0
    [[ -d "$CODEX_HOME" ]] && CODEX_DETECTED=1
    command -v codex >/dev/null 2>&1 && CODEX_DETECTED=1
    ;;
  1) CODEX_DETECTED=1 ;;
  0) CODEX_DETECTED=0 ;;
  *)
    printf "DEWEY_CODEX_DETECTED must be auto, 1, or 0 (got: %s)\n" "$DEWEY_CODEX_DETECTED" >&2
    exit 1
    ;;
esac

if [[ "$CODEX_DETECTED" -eq 0 ]]; then
  printf "Codex not detected (%s missing, 'codex' not on PATH).\n" "$CODEX_HOME" >&2
  printf "Install Codex first: https://github.com/openai/codex\n" >&2
  exit 1
fi

case "$DEWEY_CODEX_MODE" in
  plugin)
    MODE=plugin
    if ! command -v codex >/dev/null 2>&1; then
      printf "DEWEY_CODEX_MODE=plugin but the 'codex' CLI is not on PATH.\n" >&2
      exit 1
    fi
    ;;
  symlink) MODE=symlink ;;
  auto)
    if command -v codex >/dev/null 2>&1 && codex plugin marketplace --help >/dev/null 2>&1; then
      MODE=plugin
    else
      MODE=symlink
    fi
    ;;
  *)
    printf "DEWEY_CODEX_MODE must be auto, plugin, or symlink (got: %s)\n" "$DEWEY_CODEX_MODE" >&2
    exit 1
    ;;
esac

# Marketplace name comes from the manifest so forks (e.g. acme-dewey) register
# under their own name.
MARKETPLACE_NAME="dewey"
if command -v python3 >/dev/null 2>&1 && [[ -f "$DEWEY_DIR/.claude-plugin/marketplace.json" ]]; then
  _mn="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("name",""))' "$DEWEY_DIR/.claude-plugin/marketplace.json" 2>/dev/null || true)"
  [[ -n "$_mn" ]] && MARKETPLACE_NAME="$_mn"
fi

# ---- Inventory --------------------------------------------------------------
# list_plugins: "plugin_name|plugin_dir" per in-tree plugin.
list_plugins() {
  if command -v python3 >/dev/null 2>&1 && [[ -f "$DEWEY_DIR/.claude-plugin/marketplace.json" ]]; then
    python3 - "$DEWEY_DIR" <<'PY'
import json, os, sys
root = sys.argv[1]
m = json.load(open(os.path.join(root, ".claude-plugin", "marketplace.json")))
for p in m.get("plugins", []):
    src = p.get("source")
    if isinstance(src, str) and src.startswith("./"):
        d = os.path.join(root, src[2:])
        if os.path.isdir(d):
            print(f"{p['name']}|{d}")
PY
  else
    while IFS= read -r pj; do
      d="$(dirname "$(dirname "$pj")")"
      printf "%s|%s\n" "$(basename "$d")" "$d"
    done < <(find "$DEWEY_DIR/plugins" -mindepth 3 -maxdepth 3 -path '*/.claude-plugin/plugin.json' 2>/dev/null | sort)
  fi
}

# list_skills: "skill_name|skill_dir" per skill directory (symlink mode).
list_skills() {
  while IFS= read -r skill_md; do
    d="$(dirname "$skill_md")"
    printf "%s|%s\n" "$(basename "$d")" "$d"
  done < <(find "$DEWEY_DIR/plugins" -path "*/skills/*/SKILL.md" 2>/dev/null | sort)
}

skill_count=0
while IFS='|' read -r _n _p; do skill_count=$((skill_count + 1)); done < <(list_skills)
if [[ "$skill_count" -eq 0 ]]; then
  printf "No skills found in Dewey cache at %s\n" "$DEWEY_DIR" >&2
  exit 1
fi

# ---- Symlink helpers --------------------------------------------------------
# link_state <link> <src> → synced | stale | foreign | missing
link_state() {
  local link="$1" src="$2" target
  if [[ -L "$link" ]]; then
    target="$(readlink "$link")"
    if [[ "$target" == "$src" ]]; then
      echo synced
    else
      case "$target" in
        "$DEWEY_DIR"/*) echo stale ;;
        *) echo foreign ;;
      esac
    fi
  elif [[ -e "$link" ]]; then
    echo foreign
  else
    echo missing
  fi
}

# Directory symlink: <name> → <src>. Honours DRY_RUN. Echoes the state found
# BEFORE linking (synced|stale|missing|foreign) and nothing else, so callers
# can capture it; callers do the printing.
sync_dir_link() {
  local name="$1" src="$2" link="$AGENTS_SKILLS_DIR/$1" state
  state="$(link_state "$link" "$src")"
  case "$state" in
    stale|missing)
      if [[ "$DRY_RUN" -eq 0 ]]; then
        mkdir -p "$AGENTS_SKILLS_DIR"
        ln -sfn "$src" "$link"
      fi
      ;;
  esac
  echo "$state"
}

report_link() {  # <name> <src> <state> — human-readable line for sync output
  local name="$1" src="$2" state="$3"
  case "$state" in
    stale|missing)
      [[ "$DRY_RUN" -eq 1 ]] && printf "  %s %-40s → %s\n" "$(green +)" "$name" "$src"
      ;;
    foreign)
      printf "  %s %-40s (existing entry not managed by Dewey — skipped)\n" "$(yellow ●)" "$name"
      ;;
  esac
  return 0
}

remove_dir_link() {
  local name="$1" src="$2" link="$AGENTS_SKILLS_DIR/$1" state
  state="$(link_state "$link" "$src")"
  case "$state" in
    synced|stale)
      if [[ "$DRY_RUN" -eq 1 ]]; then
        note "[dry-run] Would remove symlink: $link"
      else
        rm -f "$link"
      fi
      return 0
      ;;
  esac
  return 1
}

# ---- Legacy cleanup (Dewey <= 2.2 layout) -----------------------------------
LEGACY_REMOVED=0
cleanup_legacy() {
  local link target
  if [[ -d "$LEGACY_SKILLS_DIR" ]]; then
    for link in "$LEGACY_SKILLS_DIR"/*/SKILL.md; do
      [[ -L "$link" ]] || continue
      target="$(readlink "$link")"
      case "$target" in
        "$DEWEY_DIR"/*)
          if [[ "$DRY_RUN" -eq 1 || "$STATUS_ONLY" -eq 1 ]]; then
            note "legacy file symlink (Codex never discovers these): $link"
          else
            rm -f "$link"
            rmdir "$(dirname "$link")" 2>/dev/null || true
          fi
          LEGACY_REMOVED=$((LEGACY_REMOVED + 1))
          ;;
      esac
    done
  fi
  if [[ -d "$LEGACY_CONTEXT_DIR" ]]; then
    for link in "$LEGACY_CONTEXT_DIR"/*; do
      [[ -L "$link" ]] || continue
      target="$(readlink "$link")"
      case "$target" in
        "$DEWEY_DIR"/*)
          if [[ "$DRY_RUN" -eq 1 || "$STATUS_ONLY" -eq 1 ]]; then
            note "legacy context mirror (unused by Codex): $link"
          else
            rm -f "$link"
          fi
          LEGACY_REMOVED=$((LEGACY_REMOVED + 1))
          ;;
      esac
    done
    if [[ "$DRY_RUN" -eq 0 && "$STATUS_ONLY" -eq 0 ]]; then
      rmdir "$LEGACY_CONTEXT_DIR" 2>/dev/null || true
    fi
  fi
}

# ---- Codex plugin helpers ---------------------------------------------------
codex_marketplace_root() {
  codex plugin marketplace list 2>/dev/null | awk -v n="$MARKETPLACE_NAME" 'NR > 1 && $1 == n { print $2 }'
}

# Prints the names of Dewey plugins Codex reports as installed.
codex_installed_plugins() {
  codex plugin list 2>/dev/null | awk -v suffix="@$MARKETPLACE_NAME" '
    index($1, suffix) == length($1) - length(suffix) + 1 && $2 == "installed," {
      sub(suffix "$", "", $1); print $1
    }'
}

# ---- Remove mode ------------------------------------------------------------
if [[ "$REMOVE" -eq 1 ]]; then
  removed=0
  if [[ "$MODE" == "plugin" ]]; then
    say "Removing Dewey plugins from Codex (marketplace: $MARKETPLACE_NAME)"
    while IFS= read -r name; do
      [[ -n "$name" ]] || continue
      if [[ "$DRY_RUN" -eq 1 ]]; then
        note "[dry-run] Would run: codex plugin remove $name@$MARKETPLACE_NAME"
      else
        codex plugin remove "$name@$MARKETPLACE_NAME" >/dev/null 2>&1 || note "could not remove $name@$MARKETPLACE_NAME"
      fi
      removed=$((removed + 1))
    done < <(codex_installed_plugins)
    root="$(codex_marketplace_root)"
    if [[ -n "$root" ]]; then
      if [[ "$root" == "$DEWEY_DIR" ]]; then
        if [[ "$DRY_RUN" -eq 1 ]]; then
          note "[dry-run] Would run: codex plugin marketplace remove $MARKETPLACE_NAME"
        else
          codex plugin marketplace remove "$MARKETPLACE_NAME" >/dev/null 2>&1 || note "could not remove marketplace $MARKETPLACE_NAME"
        fi
      else
        note "marketplace '$MARKETPLACE_NAME' points at $root (not the Dewey cache) — left in place"
      fi
    fi
  else
    say "Removing Dewey skill symlinks from $AGENTS_SKILLS_DIR"
    while IFS='|' read -r name src; do
      remove_dir_link "$name" "$src" && removed=$((removed + 1))
    done < <(list_skills)
  fi
  if [[ -d "$GUIDE_DIR" ]]; then
    remove_dir_link "dewey" "$GUIDE_DIR" && removed=$((removed + 1))
  fi
  cleanup_legacy
  if [[ "$DRY_RUN" -eq 1 ]]; then
    say "[dry-run] Would remove $removed item(s) and $LEGACY_REMOVED legacy symlink(s)."
  else
    say "Removed $removed item(s) and $LEGACY_REMOVED legacy symlink(s) from Codex."
  fi
  exit 0
fi

# ---- Status -----------------------------------------------------------------
if [[ "$STATUS_ONLY" -eq 1 ]]; then
  say "Dewey ↔ Codex status (mode: $MODE)"
  synced=0; missing=0
  if [[ "$MODE" == "plugin" ]]; then
    root="$(codex_marketplace_root)"
    if [[ -n "$root" ]]; then
      printf "  %s marketplace %-28s → %s\n" "$(green ✓)" "$MARKETPLACE_NAME" "$root"
    else
      printf "  %s marketplace %-28s (not registered with Codex)\n" "$(red ✗)" "$MARKETPLACE_NAME"
    fi
    installed="$(codex_installed_plugins || true)"
    while IFS='|' read -r name src; do
      if printf '%s\n' "$installed" | grep -qx "$name"; then
        printf "  %s %-40s installed\n" "$(green ✓)" "$name"
        synced=$((synced + 1))
      else
        printf "  %s %-40s (not installed in Codex yet)\n" "$(red ✗)" "$name"
        missing=$((missing + 1))
      fi
    done < <(list_plugins)
    unit="plugin"
  else
    while IFS='|' read -r name src; do
      case "$(link_state "$AGENTS_SKILLS_DIR/$name" "$src")" in
        synced)  printf "  %s %-40s → %s\n" "$(green ✓)" "$name" "$src"; synced=$((synced + 1)) ;;
        stale)   printf "  %s %-40s (stale symlink)\n" "$(yellow ●)" "$name"; missing=$((missing + 1)) ;;
        foreign) printf "  %s %-40s (existing entry, not managed by Dewey)\n" "$(yellow ●)" "$name" ;;
        missing) printf "  %s %-40s (not in Codex yet)\n" "$(red ✗)" "$name"; missing=$((missing + 1)) ;;
      esac
    done < <(list_skills)
    unit="skill"
  fi
  if [[ -d "$GUIDE_DIR" ]]; then
    case "$(link_state "$GUIDE_LINK" "$GUIDE_DIR")" in
      synced) printf "  %s %-40s → %s\n" "$(green ✓)" "dewey (Guide)" "$GUIDE_DIR" ;;
      *)      printf "  %s %-40s (not linked yet)\n" "$(red ✗)" "dewey (Guide)"; missing=$((missing + 1)) ;;
    esac
  fi
  cleanup_legacy
  echo
  printf "  %ss: synced %d, missing %d\n" "$unit" "$synced" "$missing"
  [[ "$LEGACY_REMOVED" -gt 0 ]] && printf "  Legacy symlinks to clean up: %d (run without --status)\n" "$LEGACY_REMOVED"
  printf "  Codex skills dir:  %s\n" "$AGENTS_SKILLS_DIR"
  printf "  Invoke in Codex:   type \$ and pick a skill (e.g. \$meeting-prep)\n"
  [[ "$missing" -gt 0 ]] && printf "  Run without --status to sync missing items.\n"
  exit 0
fi

# ---- Sync -------------------------------------------------------------------
synced=0
new_count=0
skipped=0
if [[ "$MODE" == "plugin" ]]; then
  say "Registering Dewey with Codex (plugin marketplace: $MARKETPLACE_NAME)"
  root="$(codex_marketplace_root)"
  if [[ -z "$root" ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      note "[dry-run] Would run: codex plugin marketplace add $DEWEY_DIR"
    else
      if ! codex plugin marketplace add "$DEWEY_DIR" >/dev/null 2>&1; then
        printf "codex plugin marketplace add %s failed\n" "$DEWEY_DIR" >&2
        exit 1
      fi
      note "registered marketplace '$MARKETPLACE_NAME' → $DEWEY_DIR"
    fi
  elif [[ "$root" != "$DEWEY_DIR" ]]; then
    note "marketplace '$MARKETPLACE_NAME' already registered → $root (using it as-is)"
  fi
  installed_before="$(codex_installed_plugins || true)"
  while IFS='|' read -r name src; do
    if [[ "$DRY_RUN" -eq 1 ]]; then
      printf "  %s %-40s (would run: codex plugin add %s@%s)\n" "$(green +)" "$name" "$name" "$MARKETPLACE_NAME"
      synced=$((synced + 1))
      continue
    fi
    if codex plugin add "$name@$MARKETPLACE_NAME" >/dev/null 2>&1; then
      synced=$((synced + 1))
      printf '%s\n' "$installed_before" | grep -qx "$name" || new_count=$((new_count + 1))
    else
      printf "  %s %-40s (codex plugin add failed)\n" "$(yellow ●)" "$name"
      skipped=$((skipped + 1))
    fi
  done < <(list_plugins)
  unit="plugin"
else
  say "Linking Dewey skills into $AGENTS_SKILLS_DIR"
  while IFS='|' read -r name src; do
    state="$(sync_dir_link "$name" "$src")"
    report_link "$name" "$src" "$state"
    case "$state" in
      synced)        synced=$((synced + 1)) ;;
      stale|missing) synced=$((synced + 1)); new_count=$((new_count + 1)) ;;
      foreign)       skipped=$((skipped + 1)) ;;
    esac
  done < <(list_skills)
  unit="skill"
fi

# The Guide rides along in both modes (it is not part of any plugin).
if [[ -d "$GUIDE_DIR" ]]; then
  state="$(sync_dir_link "dewey" "$GUIDE_DIR")"
  report_link "dewey (Guide)" "$GUIDE_DIR" "$state"
  [[ "$state" == "foreign" ]] && skipped=$((skipped + 1))
fi

cleanup_legacy

# ---- Summary ----------------------------------------------------------------
if [[ "$DRY_RUN" -eq 1 ]]; then
  echo
  say "[dry-run] Would sync $synced $unit(s) to Codex (mode: $MODE)"
  [[ "$LEGACY_REMOVED" -gt 0 ]] && say "[dry-run] Would remove $LEGACY_REMOVED legacy symlink(s)"
  exit 0
fi

if [[ "$new_count" -gt 0 ]]; then
  say "Synced $synced $unit(s) to Codex ($new_count new)"
else
  say "Codex already up to date ($synced $unit(s))"
fi
[[ "$skipped" -gt 0 ]] && note "$skipped item(s) skipped — see above"
[[ "$LEGACY_REMOVED" -gt 0 ]] && note "removed $LEGACY_REMOVED legacy symlink(s) from $CODEX_HOME"
if [[ "$MODE" == "plugin" ]]; then
  note "Codex marketplace: $MARKETPLACE_NAME → $DEWEY_DIR"
fi
note "Guide: $GUIDE_LINK"
note "Invoke in Codex: type \$ and pick a skill (e.g. \$meeting-prep). Codex picks up changes automatically."
