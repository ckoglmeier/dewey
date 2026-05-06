#!/usr/bin/env bash
# Classroom installer
#
# What this does:
#   1. Downloads the Classroom reference snapshot to ~/.claude/classroom (tarball, no git required)
#   2. Copies the Guide skill to ~/.claude/skills/classroom (so it's available immediately)
#   3. Registers the Classroom marketplace in ~/.claude/plugins/known_marketplaces.json
#   4. Installs the schedule helper to ~/.claude/classroom-schedule.sh
#   5. Installs the Codex sync helper to ~/.claude/classroom-sync-codex.sh
#   6. Installs the telemetry helper to ~/.claude/classroom-telemetry.sh
#   7. If Codex is detected (~/.codex/ or codex on PATH), mirrors skills to ~/.codex/skills/
#   8. Initializes the analytics log at ~/.claude/classroom-analytics.log
#   9. Installs a refresh + first-run hook on Claude Code SessionStart
#
# Safe to re-run. Atomic swap means readers never observe a half-written cache.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/ckoglmeier/classroom/main/install.sh | bash
#
# Or local:
#   bash ./install.sh
#
# Env overrides:
#   CLASSROOM_REPO            Repo URL (default: example GitHub URL). Used to derive tarball URL.
#   CLASSROOM_REF             Branch or tag to install (default: main). Tags are supported — use them to pin.
#   CLASSROOM_TARBALL         Full tarball URL. Overrides the derived ${CLASSROOM_REPO}/archive/... URL.
#   CLASSROOM_TARBALL_SHA256  Optional SHA-256. If set, the downloaded tarball must match.
#   CLASSROOM_DIR             Where to place the cache (default: $HOME/.claude/classroom).
#   CLASSROOM_USE_INPLACE     If 1, skip download and use whatever already exists at CLASSROOM_DIR.
#                             Used by the test sandbox; not intended for end users.

set -euo pipefail

# ---- Configurable -----------------------------------------------------------
CLASSROOM_REPO="${CLASSROOM_REPO:-https://github.com/ckoglmeier/classroom}"
CLASSROOM_REF="${CLASSROOM_REF:-main}"
CLASSROOM_DIR="${CLASSROOM_DIR:-$HOME/.claude/classroom}"
CLASSROOM_TARBALL="${CLASSROOM_TARBALL:-}"
CLASSROOM_TARBALL_SHA256="${CLASSROOM_TARBALL_SHA256:-}"
CLASSROOM_USE_INPLACE="${CLASSROOM_USE_INPLACE:-0}"
CLASSROOM_SYNC_CODEX="${CLASSROOM_SYNC_CODEX:-auto}"  # auto | 1 | 0
SETTINGS_FILE="$HOME/.claude/settings.json"
GUIDE_SKILL_DIR="$HOME/.claude/skills/classroom"
HOOK_SCRIPT="$HOME/.claude/classroom-first-run.sh"
REFRESH_SCRIPT="$HOME/.claude/classroom-refresh.sh"
SCHEDULE_SCRIPT="$HOME/.claude/classroom-schedule.sh"
SYNC_CODEX_SCRIPT="$HOME/.claude/classroom-sync-codex.sh"
TELEMETRY_SCRIPT="$HOME/.claude/classroom-telemetry.sh"
ANALYTICS_LOG="$HOME/.claude/classroom-analytics.log"
FIRST_RUN_MARKER="$HOME/.claude/classroom-onboarded"

# ---- Helpers ----------------------------------------------------------------
say() { printf "\n\033[1;36m▸\033[0m %s\n" "$*"; }
warn() { printf "\n\033[1;33m!\033[0m %s\n" "$*"; }
die() { printf "\n\033[1;31m✗\033[0m %s\n" "$*" >&2; exit 1; }

require() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

# Guard: only allow destructive ops when the path looks like the canonical
# Classroom cache. Cheap insurance against a malformed env var nuking something
# unrelated.
assert_safe_classroom_dir() {
  case "$CLASSROOM_DIR" in
    */.claude/classroom|*/.claude/classroom/) : ;;
    *) die "Refusing to operate on CLASSROOM_DIR=$CLASSROOM_DIR (must end in .claude/classroom)" ;;
  esac
}

# Derive tarball URL from repo + ref if the user didn't override.
derive_tarball_url() {
  if [ -n "$CLASSROOM_TARBALL" ]; then
    echo "$CLASSROOM_TARBALL"
    return
  fi
  local repo="${CLASSROOM_REPO%.git}"
  # GitHub serves both branches and tags via /archive/refs/{heads,tags}/<ref>.tar.gz
  # but the unified /archive/<ref>.tar.gz form works for both, so use that.
  echo "${repo}/archive/${CLASSROOM_REF}.tar.gz"
}

# Download + verify + atomically swap into $CLASSROOM_DIR.
# Echoes "refreshed" on stdout if it actually replaced an existing populated dir.
fetch_and_install_snapshot() {
  assert_safe_classroom_dir

  local url
  url="$(derive_tarball_url)"

  local tmp_root tmp_tarball stage
  tmp_root="$(mktemp -d)"
  tmp_tarball="$tmp_root/classroom.tar.gz"
  stage="$tmp_root/stage"
  mkdir -p "$stage"

  say "Downloading Classroom snapshot from $url"
  if ! curl -fsSL "$url" -o "$tmp_tarball"; then
    rm -rf "$tmp_root"
    die "Download failed: $url"
  fi

  if [ -n "$CLASSROOM_TARBALL_SHA256" ]; then
    say "Verifying tarball checksum"
    if ! echo "$CLASSROOM_TARBALL_SHA256  $tmp_tarball" | shasum -a 256 -c - >/dev/null 2>&1; then
      rm -rf "$tmp_root"
      die "Checksum mismatch: expected $CLASSROOM_TARBALL_SHA256"
    fi
  fi

  say "Extracting snapshot"
  if ! tar -xzf "$tmp_tarball" --strip-components=1 -C "$stage" 2>/dev/null; then
    rm -rf "$tmp_root"
    die "Extract failed (corrupt or unexpected tarball layout)"
  fi

  # Sanity-check the extracted snapshot before swapping.
  if [ ! -f "$stage/guide/SKILL.md" ] || [ ! -f "$stage/.claude-plugin/marketplace.json" ]; then
    rm -rf "$tmp_root"
    die "Extracted snapshot is missing guide/SKILL.md or .claude-plugin/marketplace.json"
  fi

  # Atomic swap. mv of sibling directories on the same filesystem is atomic on
  # POSIX, so the Guide can never observe a half-written cache.
  local existed=0
  if [ -d "$CLASSROOM_DIR" ] && [ -n "$(ls -A "$CLASSROOM_DIR" 2>/dev/null)" ]; then
    existed=1
  fi

  mkdir -p "$(dirname "$CLASSROOM_DIR")"

  local backup="${CLASSROOM_DIR}.old.$$"
  if [ -d "$CLASSROOM_DIR" ]; then
    mv "$CLASSROOM_DIR" "$backup"
  fi

  if ! mv "$stage" "$CLASSROOM_DIR"; then
    # Roll back if the swap failed.
    if [ -d "$backup" ]; then
      mv "$backup" "$CLASSROOM_DIR"
    fi
    rm -rf "$tmp_root"
    die "Atomic swap failed"
  fi

  if [ -d "$backup" ]; then
    assert_safe_classroom_dir
    rm -rf "$backup"
  fi

  rm -rf "$tmp_root"

  if [ "$existed" -eq 1 ]; then
    warn "Classroom cache refreshed (any local edits in $CLASSROOM_DIR were overwritten)"
  fi
}

# ---- Preflight --------------------------------------------------------------
say "Classroom installer starting"

require curl
require tar

if ! command -v claude >/dev/null 2>&1; then
  warn "Claude Code CLI ('claude') not found on PATH."
  warn "Classroom needs Claude Code installed to work. See: https://docs.claude.com/claude-code"
  warn "Continuing — the install will still configure files, but you'll need Claude Code installed before running /classroom."
fi

mkdir -p "$HOME/.claude"
mkdir -p "$HOME/.claude/skills"

# ---- Step 1: populate $CLASSROOM_DIR ----------------------------------------
if [ "$CLASSROOM_USE_INPLACE" = "1" ]; then
  say "CLASSROOM_USE_INPLACE=1 set — using existing $CLASSROOM_DIR in place"
  if [ ! -f "$CLASSROOM_DIR/guide/SKILL.md" ]; then
    die "$CLASSROOM_DIR/guide/SKILL.md missing — nothing to use in place"
  fi
elif [ -d "$CLASSROOM_DIR/.git" ]; then
  say "Detected dev checkout at $CLASSROOM_DIR (.git present) — leaving as-is"
  say "Contributors should use install-dev.sh / git pull to update."
else
  fetch_and_install_snapshot
fi

# ---- Step 2: install the Guide as a personal skill --------------------------
GUIDE_SOURCE="$CLASSROOM_DIR/guide/SKILL.md"
if [ ! -f "$GUIDE_SOURCE" ]; then
  die "Guide skill not found at $GUIDE_SOURCE. Is the Classroom snapshot intact?"
fi

if [ -f "$GUIDE_SKILL_DIR/SKILL.md" ] && ! cmp -s "$GUIDE_SOURCE" "$GUIDE_SKILL_DIR/SKILL.md"; then
  warn "Existing Guide at $GUIDE_SKILL_DIR/SKILL.md differs from the central version."
  warn "Leaving your customized version in place. Delete it and re-run if you want the latest."
else
  say "Installing Guide skill to $GUIDE_SKILL_DIR"
  mkdir -p "$GUIDE_SKILL_DIR"
  cp "$GUIDE_SOURCE" "$GUIDE_SKILL_DIR/SKILL.md"
fi

# ---- Step 3: register marketplace + hook ------------------------------------

# 3a. Register the Classroom marketplace in the plugin registry.
#     Claude Code stores marketplace state in known_marketplaces.json, not in
#     settings.json. We write there directly so we don't depend on `claude`
#     being on PATH (curl|bash installs may run outside a Claude Code session).
KNOWN_MKTS="$HOME/.claude/plugins/known_marketplaces.json"
say "Registering Classroom marketplace in $KNOWN_MKTS"

mkdir -p "$(dirname "$KNOWN_MKTS")"

if command -v python3 >/dev/null 2>&1; then
  python3 - "$KNOWN_MKTS" "$CLASSROOM_DIR" <<'PY'
import json, sys, datetime
path, classroom_dir = sys.argv[1], sys.argv[2]
try:
    with open(path) as f:
        data = json.load(f)
except (json.JSONDecodeError, FileNotFoundError):
    data = {}

data["classroom"] = {
    "source": {"source": "directory", "path": classroom_dir},
    "installLocation": classroom_dir,
    "lastUpdated": datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.000Z")
}

with open(path, "w") as f:
    json.dump(data, f, indent=2)
PY
else
  warn "python3 not found — cannot register marketplace. Run: claude plugin marketplace add $CLASSROOM_DIR"
fi

# 3b. Add the SessionStart hook in settings.json.
say "Updating $SETTINGS_FILE"

if [ ! -f "$SETTINGS_FILE" ]; then
  cat > "$SETTINGS_FILE" <<EOF
{
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
  python3 - "$SETTINGS_FILE" "$HOOK_SCRIPT" <<'PY'
import json, sys
path, hook_script = sys.argv[1], sys.argv[2]
try:
    with open(path) as f:
        data = json.load(f)
except (json.JSONDecodeError, FileNotFoundError):
    data = {}

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
  warn "Manually add the SessionStart hook to $SETTINGS_FILE."
fi

# ---- Step 4a: install the schedule helper -----------------------------------
SCHEDULE_SOURCE="$CLASSROOM_DIR/classroom-schedule.sh"
if [ -f "$SCHEDULE_SOURCE" ]; then
  say "Installing schedule helper to $SCHEDULE_SCRIPT"
  cp "$SCHEDULE_SOURCE" "$SCHEDULE_SCRIPT"
  chmod +x "$SCHEDULE_SCRIPT"
else
  warn "classroom-schedule.sh not found in snapshot — skipping schedule helper install"
fi

# ---- Step 4b: install the Codex sync helper ---------------------------------
SYNC_CODEX_SOURCE="$CLASSROOM_DIR/classroom-sync-codex.sh"
if [ -f "$SYNC_CODEX_SOURCE" ]; then
  say "Installing Codex sync helper to $SYNC_CODEX_SCRIPT"
  cp "$SYNC_CODEX_SOURCE" "$SYNC_CODEX_SCRIPT"
  chmod +x "$SYNC_CODEX_SCRIPT"
else
  warn "classroom-sync-codex.sh not found in snapshot — skipping Codex sync helper install"
fi

# ---- Step 4b2: install the telemetry helper ---------------------------------
TELEMETRY_SOURCE="$CLASSROOM_DIR/classroom-telemetry.sh"
if [ -f "$TELEMETRY_SOURCE" ]; then
  say "Installing telemetry helper to $TELEMETRY_SCRIPT"
  cp "$TELEMETRY_SOURCE" "$TELEMETRY_SCRIPT"
  chmod +x "$TELEMETRY_SCRIPT"
else
  warn "classroom-telemetry.sh not found in snapshot — skipping telemetry helper install"
fi

# ---- Step 4c: run initial Codex sync if Codex is detected -------------------
_codex_detected=0
if [ -d "$HOME/.codex" ] || command -v codex >/dev/null 2>&1; then
  _codex_detected=1
fi

if [ "$CLASSROOM_SYNC_CODEX" = "1" ] || { [ "$CLASSROOM_SYNC_CODEX" = "auto" ] && [ "$_codex_detected" -eq 1 ]; }; then
  if [ -x "$SYNC_CODEX_SCRIPT" ]; then
    say "Codex detected — syncing Classroom skills to ~/.codex/skills/"
    if ! CLASSROOM_DIR="$CLASSROOM_DIR" bash "$SYNC_CODEX_SCRIPT" 2>/dev/null; then
      warn "Codex skill sync failed — run /classroom sync manually to retry"
    fi
  fi
fi

# ---- Step 4d: initialize analytics log (if telemetry not disabled) ----------
CLASSROOM_TELEMETRY="${CLASSROOM_TELEMETRY:-1}"
if [ "$CLASSROOM_TELEMETRY" != "0" ] && [ ! -f "$ANALYTICS_LOG" ]; then
  say "Initializing analytics log at $ANALYTICS_LOG"
  touch "$ANALYTICS_LOG"
fi

# ---- Step 5: write the refresh script ---------------------------------------
say "Writing refresh script to $REFRESH_SCRIPT"
cat > "$REFRESH_SCRIPT" <<REFRESH_EOF
#!/usr/bin/env bash
# Classroom refresh script
#
# Pulls the latest snapshot of the Classroom reference repo if the local cache
# is older than CLASSROOM_REFRESH_INTERVAL hours (default 24). Background-safe,
# lock-protected, atomic swap. Always exits 0 — never breaks a session.

set -u

CLASSROOM_REPO="\${CLASSROOM_REPO:-$CLASSROOM_REPO}"
CLASSROOM_REF="\${CLASSROOM_REF:-$CLASSROOM_REF}"
CLASSROOM_DIR="\${CLASSROOM_DIR:-$CLASSROOM_DIR}"
CLASSROOM_TARBALL="\${CLASSROOM_TARBALL:-${CLASSROOM_TARBALL}}"
CLASSROOM_TARBALL_SHA256="\${CLASSROOM_TARBALL_SHA256:-${CLASSROOM_TARBALL_SHA256}}"
CLASSROOM_REFRESH_INTERVAL="\${CLASSROOM_REFRESH_INTERVAL:-24}"

LOCK_FILE="\$HOME/.claude/classroom-refresh.lock"
MARKER="\$HOME/.claude/classroom-last-refresh"
LOG="\$HOME/.claude/classroom-refresh.log"

log() {
  printf '[%s] %s\n' "\$(date -u +%Y-%m-%dT%H:%M:%SZ)" "\$*" >> "\$LOG" 2>/dev/null || true
}

# Disabled
if [ "\$CLASSROOM_REFRESH_INTERVAL" = "-1" ]; then
  exit 0
fi

# Dev checkout — contributor manages updates via git pull
if [ -d "\$CLASSROOM_DIR/.git" ]; then
  exit 0
fi

# Concurrent-execution guard
if [ -f "\$LOCK_FILE" ]; then
  exit 0
fi
touch "\$LOCK_FILE" 2>/dev/null || exit 0
trap 'rm -f "\$LOCK_FILE"' EXIT

# 24h marker check (skipped if interval is 0)
if [ "\$CLASSROOM_REFRESH_INTERVAL" != "0" ] && [ -f "\$MARKER" ]; then
  now=\$(date +%s)
  then=\$(date -r "\$MARKER" +%s 2>/dev/null || stat -c %Y "\$MARKER" 2>/dev/null || echo 0)
  age_hours=\$(( (now - then) / 3600 ))
  if [ "\$age_hours" -lt "\$CLASSROOM_REFRESH_INTERVAL" ]; then
    exit 0
  fi
fi

# Refuse weird CLASSROOM_DIR
case "\$CLASSROOM_DIR" in
  */.claude/classroom|*/.claude/classroom/) : ;;
  *) log "refusing unsafe CLASSROOM_DIR=\$CLASSROOM_DIR"; exit 0 ;;
esac

if [ -n "\$CLASSROOM_TARBALL" ]; then
  url="\$CLASSROOM_TARBALL"
else
  repo="\${CLASSROOM_REPO%.git}"
  url="\${repo}/archive/\${CLASSROOM_REF}.tar.gz"
fi

tmp_root=\$(mktemp -d 2>/dev/null) || { log "mktemp failed"; exit 0; }
tmp_tarball="\$tmp_root/classroom.tar.gz"
stage="\$tmp_root/stage"
mkdir -p "\$stage"

if ! curl -fsSL "\$url" -o "\$tmp_tarball" 2>/dev/null; then
  log "download failed: \$url"
  rm -rf "\$tmp_root"
  exit 0
fi

if [ -n "\$CLASSROOM_TARBALL_SHA256" ]; then
  if ! echo "\$CLASSROOM_TARBALL_SHA256  \$tmp_tarball" | shasum -a 256 -c - >/dev/null 2>&1; then
    log "checksum mismatch"
    rm -rf "\$tmp_root"
    exit 0
  fi
fi

if ! tar -xzf "\$tmp_tarball" --strip-components=1 -C "\$stage" 2>/dev/null; then
  log "extract failed"
  rm -rf "\$tmp_root"
  exit 0
fi

if [ ! -f "\$stage/guide/SKILL.md" ] || [ ! -f "\$stage/.claude-plugin/marketplace.json" ]; then
  log "extracted snapshot missing required files"
  rm -rf "\$tmp_root"
  exit 0
fi

backup="\${CLASSROOM_DIR}.old.\$\$"
if [ -d "\$CLASSROOM_DIR" ]; then
  mv "\$CLASSROOM_DIR" "\$backup" 2>/dev/null || { log "backup move failed"; rm -rf "\$tmp_root"; exit 0; }
fi

if ! mv "\$stage" "\$CLASSROOM_DIR" 2>/dev/null; then
  log "swap failed"
  if [ -d "\$backup" ]; then
    mv "\$backup" "\$CLASSROOM_DIR" 2>/dev/null || true
  fi
  rm -rf "\$tmp_root"
  exit 0
fi

if [ -d "\$backup" ]; then
  case "\$CLASSROOM_DIR" in
    */.claude/classroom|*/.claude/classroom/) rm -rf "\$backup" ;;
  esac
fi

rm -rf "\$tmp_root"
touch "\$MARKER"
log "refreshed from \$url"

# Post-refresh: mirror updated skills to Codex if available
SYNC_SCRIPT="\$HOME/.claude/classroom-sync-codex.sh"
if [ -x "\$SYNC_SCRIPT" ]; then
  if [ -d "\$HOME/.codex" ] || command -v codex >/dev/null 2>&1; then
    if ! CLASSROOM_DIR="\$CLASSROOM_DIR" bash "\$SYNC_SCRIPT" >/dev/null 2>&1; then
      log "codex sync failed after refresh (non-fatal)"
    else
      log "codex sync completed"
    fi
  fi
fi

exit 0
REFRESH_EOF
chmod +x "$REFRESH_SCRIPT"

# ---- Step 5: write the SessionStart hook script -----------------------------
say "Writing first-run hook to $HOOK_SCRIPT"
cat > "$HOOK_SCRIPT" <<EOF
#!/usr/bin/env bash
# Classroom SessionStart hook
# Two jobs:
#   1. On the first ever run, print a welcome message that nudges the user to /classroom.
#   2. Kick off refresh.sh in the background (lock-protected, 24h-gated, never blocks).

set -e

MARKER="$FIRST_RUN_MARKER"
REFRESH="$REFRESH_SCRIPT"

# Background refresh — portable subshell so we don't depend on \`disown\`.
if [ -x "\$REFRESH" ]; then
  ( "\$REFRESH" >/dev/null 2>&1 & )
fi

if [ -f "\$MARKER" ]; then
  exit 0
fi

# Emit first_run analytics event
if [ "\${CLASSROOM_TELEMETRY:-1}" != "0" ]; then
  printf '{"ts":"%s","event":"first_run"}\n' "\$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "\$HOME/.claude/classroom-analytics.log" 2>/dev/null || true
fi

cat <<'WELCOME'
Welcome to Classroom — your company's skill marketplace.

This is your first time. To get started, type:

  /classroom

The Guide will ask your team and role, recommend a few skills, and walk you through installing them. Everything confirms before it runs — nothing happens without your yes.
WELCOME

mkdir -p "\$(dirname "\$MARKER")"
touch "\$MARKER"
exit 0
EOF
chmod +x "$HOOK_SCRIPT"

# ---- Done -------------------------------------------------------------------
say "Classroom installed."
echo
echo "  Reference cache:  $CLASSROOM_DIR"
echo "  Guide skill:      $GUIDE_SKILL_DIR/SKILL.md"
echo "  Settings:         $SETTINGS_FILE"
echo "  Refresh script:   $REFRESH_SCRIPT"
echo "  Schedule helper:  $SCHEDULE_SCRIPT"
echo "  Codex sync:       $SYNC_CODEX_SCRIPT"
echo "  Telemetry helper: $TELEMETRY_SCRIPT"
echo "  First-run hook:   $HOOK_SCRIPT"
echo "  Analytics log:    $ANALYTICS_LOG"
echo
echo "Next: open Claude Code and you'll see a welcome message. Type /classroom to start."
