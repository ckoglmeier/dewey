#!/usr/bin/env bash
# Dewey installer — DEVELOPER / CONTRIBUTOR variant
#
# This is for Dewey contributors who want a live git checkout at
# ~/.claude/dewey that they can `git pull` and edit. Regular users should
# use install.sh instead, which is faster, has no git dependency, and gets
# updates via the background refresh script.
#
# What this does:
#   1. git clones (or pulls) the Dewey reference repo to ~/.claude/dewey
#   2. Copies the Guide skill to ~/.claude/skills/dewey
#   3. Adds the marketplace + first-run hook to ~/.claude/settings.json
#
# Usage:
#   bash ./install-dev.sh

set -euo pipefail

# ---- Configurable -----------------------------------------------------------
DEWEY_REPO="${DEWEY_REPO:-https://github.com/ckoglmeier/dewey.git}"
DEWEY_REF="${DEWEY_REF:-main}"
DEWEY_DIR="${DEWEY_DIR:-$HOME/.claude/dewey}"
SETTINGS_FILE="$HOME/.claude/settings.json"
GUIDE_SKILL_DIR="$HOME/.claude/skills/dewey"
HOOK_SCRIPT="$HOME/.claude/dewey-first-run.sh"
REFRESH_SCRIPT="$HOME/.claude/dewey-refresh.sh"
FIRST_RUN_MARKER="$HOME/.claude/dewey-onboarded"

# ---- Helpers ----------------------------------------------------------------
say() { printf "\n\033[1;36m▸\033[0m %s\n" "$*"; }
warn() { printf "\n\033[1;33m!\033[0m %s\n" "$*"; }
die() { printf "\n\033[1;31m✗\033[0m %s\n" "$*" >&2; exit 1; }

require() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

# ---- Preflight --------------------------------------------------------------
say "Dewey dev installer starting"

require git

if ! command -v claude >/dev/null 2>&1; then
  warn "Claude Code CLI ('claude') not found on PATH."
  warn "You can keep going — Claude Code can be installed later."
fi

mkdir -p "$HOME/.claude"
mkdir -p "$HOME/.claude/skills"

# ---- Step 1: clone/update the dev checkout ----------------------------------
if [ -d "$DEWEY_DIR/.git" ]; then
  say "Updating existing dev checkout at $DEWEY_DIR"
  git -C "$DEWEY_DIR" fetch --quiet origin "$DEWEY_REF"
  git -C "$DEWEY_DIR" checkout --quiet "$DEWEY_REF"
  git -C "$DEWEY_DIR" pull --quiet --ff-only origin "$DEWEY_REF"
elif [ -d "$DEWEY_DIR" ] && [ -n "$(ls -A "$DEWEY_DIR" 2>/dev/null)" ]; then
  die "$DEWEY_DIR exists but is not a git repo. Move it aside and re-run."
else
  say "Cloning dev checkout into $DEWEY_DIR"
  git clone --quiet --branch "$DEWEY_REF" "$DEWEY_REPO" "$DEWEY_DIR"
fi

# ---- Step 2: install the Guide as a personal skill --------------------------
GUIDE_SOURCE="$DEWEY_DIR/guide/SKILL.md"
if [ ! -f "$GUIDE_SOURCE" ]; then
  die "Guide skill not found at $GUIDE_SOURCE."
fi

if [ -f "$GUIDE_SKILL_DIR/SKILL.md" ] && ! cmp -s "$GUIDE_SOURCE" "$GUIDE_SKILL_DIR/SKILL.md"; then
  warn "Existing Guide at $GUIDE_SKILL_DIR/SKILL.md differs from the source. Leaving it alone."
else
  say "Installing Guide skill to $GUIDE_SKILL_DIR"
  mkdir -p "$GUIDE_SKILL_DIR"
  cp "$GUIDE_SOURCE" "$GUIDE_SKILL_DIR/SKILL.md"
fi

# ---- Step 3: register marketplace + hook in settings.json -------------------
say "Updating $SETTINGS_FILE"

if [ ! -f "$SETTINGS_FILE" ]; then
  cat > "$SETTINGS_FILE" <<EOF
{
  "extraKnownMarketplaces": {
    "dewey": {
      "source": "url",
      "url": "$DEWEY_REPO",
      "ref": "$DEWEY_REF"
    }
  },
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": "$HOOK_SCRIPT"
          }
        ]
      }
    ]
  }
}
EOF
elif command -v python3 >/dev/null 2>&1; then
  python3 - "$SETTINGS_FILE" "$DEWEY_REPO" "$DEWEY_REF" "$HOOK_SCRIPT" <<'PY'
import json, sys
path, repo, ref, hook_script = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
try:
    with open(path) as f:
        data = json.load(f)
except (json.JSONDecodeError, FileNotFoundError):
    data = {}

mkts = data.setdefault("extraKnownMarketplaces", {})
mkts["dewey"] = {"source": "url", "url": repo, "ref": ref}

hooks = data.setdefault("hooks", {})
session_start = hooks.setdefault("SessionStart", [])

needed = {"type": "command", "command": hook_script}
already = False
for entry in session_start:
    for h in entry.get("hooks", []):
        if h.get("command") == hook_script:
            already = True
            break
if not already:
    session_start.append({"matcher": "startup", "hooks": [needed]})

with open(path, "w") as f:
    json.dump(data, f, indent=2)
PY
else
  warn "python3 not found — cannot safely merge settings.json. Skipping merge."
fi

# ---- Step 4: write a no-op refresh script -----------------------------------
# refresh.sh is a no-op when DEWEY_DIR/.git exists, but we still drop a
# stub so the SessionStart hook doesn't error if it's referenced.
say "Writing no-op refresh stub to $REFRESH_SCRIPT (dev checkout updates via git pull)"
cat > "$REFRESH_SCRIPT" <<'EOF'
#!/usr/bin/env bash
# Dev mode: refresh is a no-op. Update with `git -C ~/.claude/dewey pull`.
exit 0
EOF
chmod +x "$REFRESH_SCRIPT"

# ---- Step 5: write the SessionStart hook ------------------------------------
say "Writing first-run hook to $HOOK_SCRIPT"
cat > "$HOOK_SCRIPT" <<EOF
#!/usr/bin/env bash
set -e

MARKER="$FIRST_RUN_MARKER"
REFRESH="$REFRESH_SCRIPT"

if [ -x "\$REFRESH" ]; then
  ( "\$REFRESH" >/dev/null 2>&1 & )
fi

if [ -f "\$MARKER" ]; then
  exit 0
fi

cat <<'WELCOME'
Welcome to Dewey — your company's skill marketplace.

This is your first time. To get started, type:

  /dewey

The Guide will ask your team and role, recommend a few skills, and walk you through installing them. Everything confirms before it runs — nothing happens without your yes.
WELCOME

mkdir -p "\$(dirname "\$MARKER")"
touch "\$MARKER"
exit 0
EOF
chmod +x "$HOOK_SCRIPT"

# ---- Done -------------------------------------------------------------------
say "Dewey (dev) installed."
echo
echo "  Dev checkout:   $DEWEY_DIR  (git pull to update)"
echo "  Guide skill:    $GUIDE_SKILL_DIR/SKILL.md"
echo "  Settings:       $SETTINGS_FILE"
echo "  First-run hook: $HOOK_SCRIPT"
