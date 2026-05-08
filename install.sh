#!/usr/bin/env bash
# Dewey installer
#
# What this does:
#   1. Downloads the Dewey reference snapshot to ~/.claude/dewey (tarball, no git required)
#   2. Copies the Guide skill to ~/.claude/skills/dewey (so it's available immediately)
#   3. Registers the Dewey marketplace in ~/.claude/plugins/known_marketplaces.json
#   4. Installs the Codex sync helper to ~/.claude/dewey-sync-codex.sh
#   5. Installs the telemetry helper to ~/.claude/dewey-telemetry.sh
#   6. Installs the propose helper to ~/.claude/dewey-propose.sh
#   7. If Codex is detected (~/.codex/ or codex on PATH), mirrors skills to ~/.codex/skills/
#   8. Initializes the analytics log at ~/.claude/dewey-analytics.log
#   9. Installs a refresh + first-run hook on Claude Code SessionStart
#
# Safe to re-run. Atomic swap means readers never observe a half-written cache.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/ckoglmeier/dewey/main/install.sh | bash
#
# Or local:
#   bash ./install.sh
#
# Env overrides:
#   DEWEY_REPO            Repo URL (default: example GitHub URL). Used to derive tarball URL.
#   DEWEY_REF             Branch or tag to install (default: main). Tags are supported — use them to pin.
#   DEWEY_TARBALL         Full tarball URL. Overrides the derived ${DEWEY_REPO}/archive/... URL.
#   DEWEY_TARBALL_SHA256  Optional SHA-256. If set, the downloaded tarball must match.
#   DEWEY_DIR             Where to place the cache (default: $HOME/.claude/dewey).
#   DEWEY_USE_INPLACE     If 1, skip download and use whatever already exists at DEWEY_DIR.
#                             Used by the test sandbox; not intended for end users.

set -euo pipefail

# ---- Configurable -----------------------------------------------------------
DEWEY_REPO="${DEWEY_REPO:-https://github.com/ckoglmeier/dewey}"
DEWEY_REF="${DEWEY_REF:-main}"
DEWEY_DIR="${DEWEY_DIR:-$HOME/.claude/dewey}"
DEWEY_TARBALL="${DEWEY_TARBALL:-}"
DEWEY_TARBALL_SHA256="${DEWEY_TARBALL_SHA256:-}"
DEWEY_USE_INPLACE="${DEWEY_USE_INPLACE:-0}"
DEWEY_SYNC_CODEX="${DEWEY_SYNC_CODEX:-auto}"  # auto | 1 | 0
SETTINGS_FILE="$HOME/.claude/settings.json"
GUIDE_SKILL_DIR="$HOME/.claude/skills/dewey"
HOOK_SCRIPT="$HOME/.claude/dewey-first-run.sh"
REFRESH_SCRIPT="$HOME/.claude/dewey-refresh.sh"
SYNC_CODEX_SCRIPT="$HOME/.claude/dewey-sync-codex.sh"
TELEMETRY_SCRIPT="$HOME/.claude/dewey-telemetry.sh"
PROPOSE_SCRIPT="$HOME/.claude/dewey-propose.sh"
ANALYTICS_LOG="$HOME/.claude/dewey-analytics.log"
FIRST_RUN_MARKER="$HOME/.claude/dewey-onboarded"

# ---- Helpers ----------------------------------------------------------------
say() { printf "\n\033[1;36m▸\033[0m %s\n" "$*"; }
warn() { printf "\n\033[1;33m!\033[0m %s\n" "$*"; }
die() { printf "\n\033[1;31m✗\033[0m %s\n" "$*" >&2; exit 1; }

require() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

# Guard: only allow destructive ops when the path looks like the canonical
# Dewey cache. Cheap insurance against a malformed env var nuking something
# unrelated.
assert_safe_dewey_dir() {
  case "$DEWEY_DIR" in
    */.claude/dewey|*/.claude/dewey/) : ;;
    *) die "Refusing to operate on DEWEY_DIR=$DEWEY_DIR (must end in .claude/dewey)" ;;
  esac
}

# Derive tarball URL from repo + ref if the user didn't override.
derive_tarball_url() {
  if [ -n "$DEWEY_TARBALL" ]; then
    echo "$DEWEY_TARBALL"
    return
  fi
  local repo="${DEWEY_REPO%.git}"
  # GitHub serves both branches and tags via /archive/refs/{heads,tags}/<ref>.tar.gz
  # but the unified /archive/<ref>.tar.gz form works for both, so use that.
  echo "${repo}/archive/${DEWEY_REF}.tar.gz"
}

# Download + verify + atomically swap into $DEWEY_DIR.
# Echoes "refreshed" on stdout if it actually replaced an existing populated dir.
fetch_and_install_snapshot() {
  assert_safe_dewey_dir

  local url
  url="$(derive_tarball_url)"

  local tmp_root tmp_tarball stage
  tmp_root="$(mktemp -d)"
  tmp_tarball="$tmp_root/dewey.tar.gz"
  stage="$tmp_root/stage"
  mkdir -p "$stage"

  say "Downloading Dewey snapshot from $url"
  if ! curl -fsSL "$url" -o "$tmp_tarball"; then
    rm -rf "$tmp_root"
    die "Download failed: $url"
  fi

  if [ -n "$DEWEY_TARBALL_SHA256" ]; then
    say "Verifying tarball checksum"
    if ! echo "$DEWEY_TARBALL_SHA256  $tmp_tarball" | shasum -a 256 -c - >/dev/null 2>&1; then
      rm -rf "$tmp_root"
      die "Checksum mismatch: expected $DEWEY_TARBALL_SHA256"
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
  if [ -d "$DEWEY_DIR" ] && [ -n "$(ls -A "$DEWEY_DIR" 2>/dev/null)" ]; then
    existed=1
  fi

  mkdir -p "$(dirname "$DEWEY_DIR")"

  local backup="${DEWEY_DIR}.old.$$"
  if [ -d "$DEWEY_DIR" ]; then
    mv "$DEWEY_DIR" "$backup"
  fi

  if ! mv "$stage" "$DEWEY_DIR"; then
    # Roll back if the swap failed.
    if [ -d "$backup" ]; then
      mv "$backup" "$DEWEY_DIR"
    fi
    rm -rf "$tmp_root"
    die "Atomic swap failed"
  fi

  if [ -d "$backup" ]; then
    assert_safe_dewey_dir
    rm -rf "$backup"
  fi

  rm -rf "$tmp_root"

  if [ "$existed" -eq 1 ]; then
    warn "Dewey cache refreshed (any local edits in $DEWEY_DIR were overwritten)"
  fi
}

# ---- Preflight --------------------------------------------------------------
say "Dewey installer starting"

require curl
require tar
require python3

if ! command -v claude >/dev/null 2>&1; then
  warn "Claude Code CLI ('claude') not found on PATH."
  warn "Dewey needs Claude Code installed to work. See: https://docs.claude.com/claude-code"
  warn "Continuing — the install will still configure files, but you'll need Claude Code installed before running /dewey."
fi

mkdir -p "$HOME/.claude"
mkdir -p "$HOME/.claude/skills"

# ---- Step 0: Classroom → Dewey migration (v2.0+) ---------------------------
# If a prior Classroom install is present, hard-rename its files/dirs to the
# new Dewey-prefixed equivalents. Idempotent: no-op if nothing to migrate.
# Records what changed in ~/.claude/dewey-migration.log.
MIGRATION_LOG="$HOME/.claude/dewey-migration.log"
_migrated_anything=0
_log_migration() {
  if [ "$_migrated_anything" -eq 0 ]; then
    _migrated_anything=1
    say "Migrating prior Classroom install → Dewey"
    {
      echo
      echo "=== Migrated Classroom → Dewey at $(date) ==="
    } >> "$MIGRATION_LOG"
  fi
  echo "  $1" >> "$MIGRATION_LOG"
  printf "  %s\n" "$1"
}

# Refuse to migrate if both old and new exist (corrupted state from a partial run)
if [ -e "$HOME/.claude/classroom" ] && [ -e "$HOME/.claude/dewey" ]; then
  die "Both ~/.claude/classroom and ~/.claude/dewey exist. Pick one to remove (probably ~/.claude/classroom) and re-run."
fi
if [ -e "$HOME/.claude/skills/classroom" ] && [ -e "$HOME/.claude/skills/dewey" ]; then
  die "Both ~/.claude/skills/classroom and ~/.claude/skills/dewey exist. Pick one to remove and re-run."
fi

# Cache directory
if [ -d "$HOME/.claude/classroom" ] && [ ! -e "$HOME/.claude/dewey" ]; then
  mv "$HOME/.claude/classroom" "$HOME/.claude/dewey"
  _log_migration "renamed ~/.claude/classroom → ~/.claude/dewey"
fi

# Guide skill directory
if [ -d "$HOME/.claude/skills/classroom" ] && [ ! -e "$HOME/.claude/skills/dewey" ]; then
  mv "$HOME/.claude/skills/classroom" "$HOME/.claude/skills/dewey"
  _log_migration "renamed ~/.claude/skills/classroom → ~/.claude/skills/dewey"
fi

# Per-helper bookkeeping files
for old_new in \
  "classroom-onboarded:dewey-onboarded" \
  "classroom-first-run.sh:dewey-first-run.sh" \
  "classroom-refresh.sh:dewey-refresh.sh" \
  "classroom-refresh.log:dewey-refresh.log" \
  "classroom-last-refresh:dewey-last-refresh" \
  "classroom-refresh.lock:dewey-refresh.lock" \
  "classroom-analytics.log:dewey-analytics.log" \
  "classroom-author:dewey-author"
do
  old="${old_new%%:*}"
  new="${old_new##*:}"
  if [ -e "$HOME/.claude/$old" ] && [ ! -e "$HOME/.claude/$new" ]; then
    mv "$HOME/.claude/$old" "$HOME/.claude/$new"
    _log_migration "renamed ~/.claude/$old → ~/.claude/$new"
  fi
done

# Old helper scripts: just remove them; new ones will be installed below
for old_helper in classroom-propose.sh classroom-sync-codex.sh classroom-telemetry.sh classroom-schedule.sh; do
  if [ -e "$HOME/.claude/$old_helper" ]; then
    rm -f "$HOME/.claude/$old_helper"
    _log_migration "removed obsolete helper ~/.claude/$old_helper (replaced by dewey-* equivalent)"
  fi
done

# known_marketplaces.json: rename "classroom" key → "dewey" and update installLocation
KNOWN_MARKETS="$HOME/.claude/plugins/known_marketplaces.json"
if [ -f "$KNOWN_MARKETS" ]; then
  if python3 -c "
import json, sys
p = '$KNOWN_MARKETS'
d = json.load(open(p))
if 'classroom' in d:
    e = d.pop('classroom')
    if isinstance(e, dict) and 'installLocation' in e:
        e['installLocation'] = e['installLocation'].replace('/classroom', '/dewey').replace('classroom', 'dewey') if e['installLocation'].endswith('classroom') else e['installLocation'].replace('/.claude/classroom', '/.claude/dewey')
    if isinstance(e, dict) and isinstance(e.get('source'), dict) and e['source'].get('source') == 'directory' and 'path' in e['source']:
        e['source']['path'] = e['source']['path'].replace('/.claude/classroom', '/.claude/dewey')
    d['dewey'] = e
    json.dump(d, open(p, 'w'), indent=2)
    open(p, 'a').write('\n')
    print('migrated')
" 2>/dev/null | grep -q migrated; then
    _log_migration "rewrote ~/.claude/plugins/known_marketplaces.json: 'classroom' key → 'dewey'"
  fi
fi

# settings.json SessionStart hooks: rewrite classroom-refresh.sh / classroom-first-run.sh references
SETTINGS_FILE="$HOME/.claude/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
  if python3 -c "
import json, sys
p = '$SETTINGS_FILE'
try:
    d = json.load(open(p))
except Exception:
    sys.exit(0)
text_before = json.dumps(d, sort_keys=True)
def walk(o):
    if isinstance(o, dict):
        for k, v in list(o.items()):
            o[k] = walk(v)
        return o
    if isinstance(o, list):
        return [walk(x) for x in o]
    if isinstance(o, str):
        return (o
                .replace('classroom-refresh.sh', 'dewey-refresh.sh')
                .replace('classroom-first-run.sh', 'dewey-first-run.sh')
                .replace('/.claude/classroom', '/.claude/dewey'))
    return o
d = walk(d)
text_after = json.dumps(d, sort_keys=True)
if text_before != text_after:
    json.dump(d, open(p, 'w'), indent=2)
    open(p, 'a').write('\n')
    print('migrated')
" 2>/dev/null | grep -q migrated; then
    _log_migration "rewrote ~/.claude/settings.json hook paths from classroom-* to dewey-*"
  fi
fi

if [ "$_migrated_anything" -eq 1 ]; then
  say "Migration complete. Details: $MIGRATION_LOG"
fi

# ---- Step 1: populate $DEWEY_DIR ----------------------------------------
if [ "$DEWEY_USE_INPLACE" = "1" ]; then
  say "DEWEY_USE_INPLACE=1 set — using existing $DEWEY_DIR in place"
  if [ ! -f "$DEWEY_DIR/guide/SKILL.md" ]; then
    die "$DEWEY_DIR/guide/SKILL.md missing — nothing to use in place"
  fi
elif [ -d "$DEWEY_DIR/.git" ]; then
  say "Detected dev checkout at $DEWEY_DIR (.git present) — leaving as-is"
  say "Contributors should use install-dev.sh / git pull to update."
else
  fetch_and_install_snapshot
fi

# ---- Step 2: install the Guide as a personal skill --------------------------
GUIDE_SOURCE="$DEWEY_DIR/guide/SKILL.md"
if [ ! -f "$GUIDE_SOURCE" ]; then
  die "Guide skill not found at $GUIDE_SOURCE. Is the Dewey snapshot intact?"
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

# 3a. Register the Dewey marketplace in the plugin registry.
#     Claude Code stores marketplace state in known_marketplaces.json, not in
#     settings.json. We write there directly so we don't depend on `claude`
#     being on PATH (curl|bash installs may run outside a Claude Code session).
KNOWN_MKTS="$HOME/.claude/plugins/known_marketplaces.json"
say "Registering Dewey marketplace in $KNOWN_MKTS"

mkdir -p "$(dirname "$KNOWN_MKTS")"

if command -v python3 >/dev/null 2>&1; then
  python3 - "$KNOWN_MKTS" "$DEWEY_DIR" <<'PY'
import json, sys, datetime
path, dewey_dir = sys.argv[1], sys.argv[2]
try:
    with open(path) as f:
        data = json.load(f)
except (json.JSONDecodeError, FileNotFoundError):
    data = {}

data["dewey"] = {
    "source": {"source": "directory", "path": dewey_dir},
    "installLocation": dewey_dir,
    "lastUpdated": datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%S.000Z")
}

with open(path, "w") as f:
    json.dump(data, f, indent=2)
PY
else
  warn "python3 not found — cannot register marketplace. Run: claude plugin marketplace add $DEWEY_DIR"
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

# Note: scheduling is handled by the host (Claude Code Routines, Cowork
# scheduled-tasks). Dewey no longer ships a schedule helper.
# See docs/scheduling.md for the rationale.

# ---- Step 4b: install the Codex sync helper ---------------------------------
SYNC_CODEX_SOURCE="$DEWEY_DIR/dewey-sync-codex.sh"
if [ -f "$SYNC_CODEX_SOURCE" ]; then
  say "Installing Codex sync helper to $SYNC_CODEX_SCRIPT"
  cp "$SYNC_CODEX_SOURCE" "$SYNC_CODEX_SCRIPT"
  chmod +x "$SYNC_CODEX_SCRIPT"
else
  warn "dewey-sync-codex.sh not found in snapshot — skipping Codex sync helper install"
fi

# ---- Step 4b2: install the telemetry helper ---------------------------------
TELEMETRY_SOURCE="$DEWEY_DIR/dewey-telemetry.sh"
if [ -f "$TELEMETRY_SOURCE" ]; then
  say "Installing telemetry helper to $TELEMETRY_SCRIPT"
  cp "$TELEMETRY_SOURCE" "$TELEMETRY_SCRIPT"
  chmod +x "$TELEMETRY_SCRIPT"
else
  warn "dewey-telemetry.sh not found in snapshot — skipping telemetry helper install"
fi

# ---- Step 4b3: install the propose helper -----------------------------------
PROPOSE_SOURCE="$DEWEY_DIR/dewey-propose.sh"
if [ -f "$PROPOSE_SOURCE" ]; then
  say "Installing propose helper to $PROPOSE_SCRIPT"
  cp "$PROPOSE_SOURCE" "$PROPOSE_SCRIPT"
  chmod +x "$PROPOSE_SCRIPT"
else
  warn "dewey-propose.sh not found in snapshot — skipping propose helper install"
fi

# ---- Step 4c: run initial Codex sync if Codex is detected -------------------
_codex_detected=0
if [ -d "$HOME/.codex" ] || command -v codex >/dev/null 2>&1; then
  _codex_detected=1
fi

if [ "$DEWEY_SYNC_CODEX" = "1" ] || { [ "$DEWEY_SYNC_CODEX" = "auto" ] && [ "$_codex_detected" -eq 1 ]; }; then
  if [ -x "$SYNC_CODEX_SCRIPT" ]; then
    say "Codex detected — syncing Dewey skills to ~/.codex/skills/"
    if ! DEWEY_DIR="$DEWEY_DIR" bash "$SYNC_CODEX_SCRIPT" 2>/dev/null; then
      warn "Codex skill sync failed — run /dewey sync manually to retry"
    fi
  fi
fi

# ---- Step 4d: initialize analytics log (if telemetry not disabled) ----------
DEWEY_TELEMETRY="${DEWEY_TELEMETRY:-1}"
if [ "$DEWEY_TELEMETRY" != "0" ] && [ ! -f "$ANALYTICS_LOG" ]; then
  say "Initializing analytics log at $ANALYTICS_LOG"
  touch "$ANALYTICS_LOG"
fi

# ---- Step 5: write the refresh script ---------------------------------------
say "Writing refresh script to $REFRESH_SCRIPT"
cat > "$REFRESH_SCRIPT" <<REFRESH_EOF
#!/usr/bin/env bash
# Dewey refresh script
#
# Pulls the latest snapshot of the Dewey reference repo if the local cache
# is older than DEWEY_REFRESH_INTERVAL hours (default 24). Background-safe,
# lock-protected, atomic swap. Always exits 0 — never breaks a session.

set -u

DEWEY_REPO="\${DEWEY_REPO:-$DEWEY_REPO}"
DEWEY_REF="\${DEWEY_REF:-$DEWEY_REF}"
DEWEY_DIR="\${DEWEY_DIR:-$DEWEY_DIR}"
DEWEY_TARBALL="\${DEWEY_TARBALL:-${DEWEY_TARBALL}}"
DEWEY_TARBALL_SHA256="\${DEWEY_TARBALL_SHA256:-${DEWEY_TARBALL_SHA256}}"
DEWEY_REFRESH_INTERVAL="\${DEWEY_REFRESH_INTERVAL:-24}"

LOCK_FILE="\$HOME/.claude/dewey-refresh.lock"
MARKER="\$HOME/.claude/dewey-last-refresh"
LOG="\$HOME/.claude/dewey-refresh.log"

log() {
  printf '[%s] %s\n' "\$(date -u +%Y-%m-%dT%H:%M:%SZ)" "\$*" >> "\$LOG" 2>/dev/null || true
}

# Disabled
if [ "\$DEWEY_REFRESH_INTERVAL" = "-1" ]; then
  exit 0
fi

# Dev checkout — contributor manages updates via git pull
if [ -d "\$DEWEY_DIR/.git" ]; then
  exit 0
fi

# Concurrent-execution guard
if [ -f "\$LOCK_FILE" ]; then
  exit 0
fi
touch "\$LOCK_FILE" 2>/dev/null || exit 0
trap 'rm -f "\$LOCK_FILE"' EXIT

# 24h marker check (skipped if interval is 0)
if [ "\$DEWEY_REFRESH_INTERVAL" != "0" ] && [ -f "\$MARKER" ]; then
  now=\$(date +%s)
  then=\$(date -r "\$MARKER" +%s 2>/dev/null || stat -c %Y "\$MARKER" 2>/dev/null || echo 0)
  age_hours=\$(( (now - then) / 3600 ))
  if [ "\$age_hours" -lt "\$DEWEY_REFRESH_INTERVAL" ]; then
    exit 0
  fi
fi

# Refuse weird DEWEY_DIR
case "\$DEWEY_DIR" in
  */.claude/dewey|*/.claude/dewey/) : ;;
  *) log "refusing unsafe DEWEY_DIR=\$DEWEY_DIR"; exit 0 ;;
esac

if [ -n "\$DEWEY_TARBALL" ]; then
  url="\$DEWEY_TARBALL"
else
  repo="\${DEWEY_REPO%.git}"
  url="\${repo}/archive/\${DEWEY_REF}.tar.gz"
fi

tmp_root=\$(mktemp -d 2>/dev/null) || { log "mktemp failed"; exit 0; }
tmp_tarball="\$tmp_root/dewey.tar.gz"
stage="\$tmp_root/stage"
mkdir -p "\$stage"

if ! curl -fsSL "\$url" -o "\$tmp_tarball" 2>/dev/null; then
  log "download failed: \$url"
  rm -rf "\$tmp_root"
  exit 0
fi

if [ -n "\$DEWEY_TARBALL_SHA256" ]; then
  if ! echo "\$DEWEY_TARBALL_SHA256  \$tmp_tarball" | shasum -a 256 -c - >/dev/null 2>&1; then
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

backup="\${DEWEY_DIR}.old.\$\$"
if [ -d "\$DEWEY_DIR" ]; then
  mv "\$DEWEY_DIR" "\$backup" 2>/dev/null || { log "backup move failed"; rm -rf "\$tmp_root"; exit 0; }
fi

if ! mv "\$stage" "\$DEWEY_DIR" 2>/dev/null; then
  log "swap failed"
  if [ -d "\$backup" ]; then
    mv "\$backup" "\$DEWEY_DIR" 2>/dev/null || true
  fi
  rm -rf "\$tmp_root"
  exit 0
fi

if [ -d "\$backup" ]; then
  case "\$DEWEY_DIR" in
    */.claude/dewey|*/.claude/dewey/) rm -rf "\$backup" ;;
  esac
fi

rm -rf "\$tmp_root"
touch "\$MARKER"
log "refreshed from \$url"

# Post-refresh: mirror updated skills to Codex if available
SYNC_SCRIPT="\$HOME/.claude/dewey-sync-codex.sh"
if [ -x "\$SYNC_SCRIPT" ]; then
  if [ -d "\$HOME/.codex" ] || command -v codex >/dev/null 2>&1; then
    if ! DEWEY_DIR="\$DEWEY_DIR" bash "\$SYNC_SCRIPT" >/dev/null 2>&1; then
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
# Dewey SessionStart hook
# Two jobs:
#   1. On the first ever run, print a welcome message that nudges the user to /dewey.
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
if [ "\${DEWEY_TELEMETRY:-1}" != "0" ]; then
  printf '{"ts":"%s","event":"first_run"}\n' "\$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "\$HOME/.claude/dewey-analytics.log" 2>/dev/null || true
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
say "Dewey installed."
echo
echo "  Reference cache:  $DEWEY_DIR"
echo "  Guide skill:      $GUIDE_SKILL_DIR/SKILL.md"
echo "  Settings:         $SETTINGS_FILE"
echo "  Refresh script:   $REFRESH_SCRIPT"
echo "  Codex sync:       $SYNC_CODEX_SCRIPT"
echo "  Telemetry helper: $TELEMETRY_SCRIPT"
echo "  Propose helper:   $PROPOSE_SCRIPT"
echo "  First-run hook:   $HOOK_SCRIPT"
echo "  Analytics log:    $ANALYTICS_LOG"
echo
echo "Next: open Claude Code and you'll see a welcome message. Type /dewey to start."
