# ============================================================================
# LAYER 10: CODEX SYNC
# ============================================================================
section "Layer 10 — Codex sync (dewey-sync-codex.sh)"

SYNC_SRC="$REPO_ROOT/dewey-sync-codex.sh"

check "dewey-sync-codex.sh exists" \
  "test -f '$SYNC_SRC'"

check "dewey-sync-codex.sh has clean bash syntax" \
  "bash -n '$SYNC_SRC'"

# install.sh drops the sync script
check "install.sh installs dewey-sync-codex.sh to \$HOME/.claude" \
  "test -x '$SANDBOX/.claude/dewey-sync-codex.sh'"

check "installed dewey-sync-codex.sh has clean bash syntax" \
  "bash -n '$SANDBOX/.claude/dewey-sync-codex.sh'"

# --dry-run: skills found in the Dewey cache, printed but not written
SYNC_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$SYNC_SANDBOX")
# Give it a fake ~/.codex so Codex is "detected"
mkdir -p "$SYNC_SANDBOX/.codex"

check "sync --dry-run lists skills without writing files" \
  "
sync_out=\$(DEWEY_DIR='$REPO_ROOT' CODEX_HOME='$SYNC_SANDBOX/.codex' HOME='$SYNC_SANDBOX' \
  bash '$SYNC_SRC' --dry-run 2>&1)
# Must mention at least one skill or 'dry-run'
echo \"\$sync_out\" | grep -qiE '(dry-run|skill|SKILL)'
# Must NOT have created any files in codex skills dir
test ! -d '$SYNC_SANDBOX/.codex/skills' || test -z \"\$(find '$SYNC_SANDBOX/.codex/skills' -type f -o -type l 2>/dev/null)\"
"

# --status: runs without error
check "sync --status exits 0 and prints output" \
  "
sync_out=\$(DEWEY_DIR='$REPO_ROOT' CODEX_HOME='$SYNC_SANDBOX/.codex' HOME='$SYNC_SANDBOX' \
  bash '$SYNC_SRC' --status 2>&1)
echo \"\$sync_out\" | grep -qiE '(synced|missing|not in Codex|skill)'
"

# Actual sync: creates symlinks
LIVE_SYNC_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$LIVE_SYNC_SANDBOX")
mkdir -p "$LIVE_SYNC_SANDBOX/.codex"

check "sync (no flags) creates symlinks in ~/.codex/skills/" \
  "
DEWEY_DIR='$REPO_ROOT' CODEX_HOME='$LIVE_SYNC_SANDBOX/.codex' HOME='$LIVE_SYNC_SANDBOX' \
  bash '$SYNC_SRC' >/dev/null 2>&1
test -d '$LIVE_SYNC_SANDBOX/.codex/skills'
find '$LIVE_SYNC_SANDBOX/.codex/skills' -name 'SKILL.md' | grep -q .
"

check "synced SKILL.md files are symlinks (not copies)" \
  "find '$LIVE_SYNC_SANDBOX/.codex/skills' -name 'SKILL.md' -type l | grep -q ."

check "synced symlinks point to the Dewey cache" \
  "
python3 -c '
import os, sys
skills_dir = \"$LIVE_SYNC_SANDBOX/.codex/skills\"
dewey_dir = \"$REPO_ROOT\"
for root, dirs, files in os.walk(skills_dir):
    for f in files:
        if f == \"SKILL.md\":
            p = os.path.join(root, f)
            target = os.readlink(p)
            assert target.startswith(dewey_dir), f\"symlink {p} points outside dewey: {target}\"
'
"

check "Guide skill (dewey) is included in sync" \
  "test -L '$LIVE_SYNC_SANDBOX/.codex/skills/dewey/SKILL.md'"

# Context bundles are symlinked to ~/.codex/context/<plugin>/
check "sync mirrors context dirs to ~/.codex/context/<plugin>/" \
  "
test -L '$LIVE_SYNC_SANDBOX/.codex/context/competitive-intelligence' && \
  target=\$(readlink '$LIVE_SYNC_SANDBOX/.codex/context/competitive-intelligence') && \
  echo \"\$target\" | grep -q 'plugins/competitive-intelligence/context'
"

check "context symlink resolves to a real directory containing context.md" \
  "test -f '$LIVE_SYNC_SANDBOX/.codex/context/competitive-intelligence/positioning/context.md'"

# --remove: removes symlinks
check "sync --remove removes only Dewey symlinks" \
  "
DEWEY_DIR='$REPO_ROOT' CODEX_HOME='$LIVE_SYNC_SANDBOX/.codex' HOME='$LIVE_SYNC_SANDBOX' \
  bash '$SYNC_SRC' --remove >/dev/null 2>&1
# After removal, no Dewey SKILL.md symlinks should remain
remaining=\$(find '$LIVE_SYNC_SANDBOX/.codex/skills' -name 'SKILL.md' -type l 2>/dev/null | wc -l | tr -d ' ')
test \"\$remaining\" = '0' && \
# Context symlinks should also be gone
! test -L '$LIVE_SYNC_SANDBOX/.codex/context/competitive-intelligence'
"

# Codex not detected: exits with error
NO_CODEX_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$NO_CODEX_SANDBOX")
check "sync exits non-zero when Codex not detected and HOME has no ~/.codex" \
  "
DEWEY_DIR='$REPO_ROOT' CODEX_HOME='$NO_CODEX_SANDBOX/.codex' HOME='$NO_CODEX_SANDBOX' DEWEY_CODEX_DETECTED=0 \
  bash '$SYNC_SRC' >/dev/null 2>&1; test \$? -ne 0
"

# Dewey not installed: exits with error
NO_DEWEY_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$NO_DEWEY_SANDBOX")
mkdir -p "$NO_DEWEY_SANDBOX/.codex"
check "sync exits non-zero when DEWEY_DIR missing" \
  "
DEWEY_DIR='$NO_DEWEY_SANDBOX/nonexistent' CODEX_HOME='$NO_DEWEY_SANDBOX/.codex' HOME='$NO_DEWEY_SANDBOX' \
  bash '$SYNC_SRC' >/dev/null 2>&1; test \$? -ne 0
"

# --agents-md: generates AGENTS.md
AGENTS_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$AGENTS_SANDBOX")
mkdir -p "$AGENTS_SANDBOX/.codex"
check "sync --agents-md writes an AGENTS.md file" \
  "
DEWEY_DIR='$REPO_ROOT' CODEX_HOME='$AGENTS_SANDBOX/.codex' HOME='$AGENTS_SANDBOX' \
  bash '$SYNC_SRC' --agents-md '$AGENTS_SANDBOX' >/dev/null 2>&1
test -f '$AGENTS_SANDBOX/AGENTS.md'
grep -q 'Dewey' '$AGENTS_SANDBOX/AGENTS.md'
"

check "generated AGENTS.md mentions at least one skill" \
  "grep -qE '^\- \`/' '$AGENTS_SANDBOX/AGENTS.md'"

# install.sh with DEWEY_SYNC_CODEX=0 must not run sync
NO_SYNC_SANDBOX="$(mktemp -d)"
NO_SYNC_DEWEY="$NO_SYNC_SANDBOX/.claude/dewey"
TMPDIRS_TO_CLEAN+=("$NO_SYNC_SANDBOX")
mkdir -p "$NO_SYNC_DEWEY"
cp -R "$REPO_ROOT/." "$NO_SYNC_DEWEY/"
check "install.sh skips Codex sync when DEWEY_SYNC_CODEX=0" \
  "
DEWEY_SYNC_CODEX=0 HOME='$NO_SYNC_SANDBOX' DEWEY_DIR='$NO_SYNC_DEWEY' \
  DEWEY_REPO='file://$REPO_ROOT' DEWEY_REF=main DEWEY_USE_INPLACE=1 \
  bash '$REPO_ROOT/install.sh' >/dev/null 2>&1
test ! -d '$NO_SYNC_SANDBOX/.codex/skills'
"

# docs/codex-sync.md exists
check "docs/codex-sync.md exists" \
  "test -f '$REPO_ROOT/docs/codex-sync.md'"
