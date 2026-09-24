# ============================================================================
# LAYER 10: CODEX SYNC
# ============================================================================
# The suite forces DEWEY_CODEX_MODE=symlink (tests/run.sh) so no test touches
# the real `codex` CLI. The plugin-marketplace mode is exercised by an opt-in
# live test at the end (DEWEY_TEST_CODEX_PLUGIN=1 with `codex` on PATH).
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
echo \"\$sync_out\" | grep -qiE '(dry-run|skill|SKILL)'
test ! -e '$SYNC_SANDBOX/.agents/skills'
test ! -e '$SYNC_SANDBOX/.codex/skills'
"

# --status: runs without error
check "sync --status exits 0 and prints output" \
  "
sync_out=\$(DEWEY_DIR='$REPO_ROOT' CODEX_HOME='$SYNC_SANDBOX/.codex' HOME='$SYNC_SANDBOX' \
  bash '$SYNC_SRC' --status 2>&1)
echo \"\$sync_out\" | grep -qiE '(synced|missing|not in Codex|skill)'
"

# Actual sync: directory symlinks under ~/.agents/skills/
LIVE_SYNC_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$LIVE_SYNC_SANDBOX")
mkdir -p "$LIVE_SYNC_SANDBOX/.codex"

# Seed pre-2.3 leftovers that the sync must clean up: a per-file SKILL.md symlink
# (never discovered by Codex) and a ~/.codex/context mirror. Plus one foreign
# entry that must be left alone.
mkdir -p "$LIVE_SYNC_SANDBOX/.codex/skills/meeting-prep" "$LIVE_SYNC_SANDBOX/.codex/context" \
         "$LIVE_SYNC_SANDBOX/.codex/skills/someone-elses"
ln -s "$REPO_ROOT/plugins/ops-essentials/skills/meeting-prep/SKILL.md" "$LIVE_SYNC_SANDBOX/.codex/skills/meeting-prep/SKILL.md"
ln -s "$REPO_ROOT/plugins/competitive-intelligence/context" "$LIVE_SYNC_SANDBOX/.codex/context/competitive-intelligence"
printf -- "---\nname: someone-elses\ndescription: not ours\n---\nbody\n" > "$LIVE_SYNC_SANDBOX/.codex/skills/someone-elses/SKILL.md"

check "sync (no flags) creates skill directory symlinks in ~/.agents/skills/" \
  "
DEWEY_DIR='$REPO_ROOT' CODEX_HOME='$LIVE_SYNC_SANDBOX/.codex' HOME='$LIVE_SYNC_SANDBOX' \
  bash '$SYNC_SRC' >/dev/null 2>&1
test -d '$LIVE_SYNC_SANDBOX/.agents/skills'
test -L '$LIVE_SYNC_SANDBOX/.agents/skills/meeting-prep'
test -f '$LIVE_SYNC_SANDBOX/.agents/skills/meeting-prep/SKILL.md'
"

check "synced entries are symlinked directories, not symlinked SKILL.md files" \
  "
for link in '$LIVE_SYNC_SANDBOX'/.agents/skills/*; do
  test -L \"\$link\" || exit 1
  test -d \"\$link\" || exit 1
  test ! -L \"\$link/SKILL.md\" || exit 1
done
"

check "synced symlinks point to the Dewey cache" \
  "
python3 -c '
import os
skills_dir = \"$LIVE_SYNC_SANDBOX/.agents/skills\"
dewey_dir = \"$REPO_ROOT\"
for name in os.listdir(skills_dir):
    p = os.path.join(skills_dir, name)
    assert os.path.islink(p), p + \" is not a symlink\"
    target = os.readlink(p)
    assert target.startswith(dewey_dir), f\"symlink {p} points outside dewey: {target}\"
'
"

check "Guide skill (dewey) is linked as ~/.agents/skills/dewey" \
  "test -L '$LIVE_SYNC_SANDBOX/.agents/skills/dewey' && test -f '$LIVE_SYNC_SANDBOX/.agents/skills/dewey/SKILL.md'"

check "sync removes legacy ~/.codex/skills/<name>/SKILL.md file symlinks" \
  "test ! -e '$LIVE_SYNC_SANDBOX/.codex/skills/meeting-prep/SKILL.md' && test ! -d '$LIVE_SYNC_SANDBOX/.codex/skills/meeting-prep'"

check "sync removes legacy ~/.codex/context mirrors" \
  "test ! -e '$LIVE_SYNC_SANDBOX/.codex/context/competitive-intelligence' && test ! -d '$LIVE_SYNC_SANDBOX/.codex/context'"

check "sync leaves non-Dewey entries in ~/.codex/skills alone" \
  "test -f '$LIVE_SYNC_SANDBOX/.codex/skills/someone-elses/SKILL.md'"

check "sync does not create ~/.codex/context (not a Codex concept)" \
  "test ! -e '$LIVE_SYNC_SANDBOX/.codex/context'"

check "sync is idempotent (second run reports up to date)" \
  "
out=\$(DEWEY_DIR='$REPO_ROOT' CODEX_HOME='$LIVE_SYNC_SANDBOX/.codex' HOME='$LIVE_SYNC_SANDBOX' \
  bash '$SYNC_SRC' 2>&1)
echo \"\$out\" | grep -q 'already up to date'
"

check "sync --status reports every skill as synced" \
  "
out=\$(DEWEY_DIR='$REPO_ROOT' CODEX_HOME='$LIVE_SYNC_SANDBOX/.codex' HOME='$LIVE_SYNC_SANDBOX' \
  bash '$SYNC_SRC' --status 2>&1)
echo \"\$out\" | grep -q 'missing 0'
"

# --remove: removes symlinks
mkdir -p "$LIVE_SYNC_SANDBOX/.agents/skills/my-own-skill"
printf -- "---\nname: my-own-skill\ndescription: mine\n---\nbody\n" > "$LIVE_SYNC_SANDBOX/.agents/skills/my-own-skill/SKILL.md"
check "sync --remove removes only Dewey symlinks" \
  "
DEWEY_DIR='$REPO_ROOT' CODEX_HOME='$LIVE_SYNC_SANDBOX/.codex' HOME='$LIVE_SYNC_SANDBOX' \
  bash '$SYNC_SRC' --remove >/dev/null 2>&1
remaining=\$(find '$LIVE_SYNC_SANDBOX/.agents/skills' -maxdepth 1 -type l 2>/dev/null | wc -l | tr -d ' ')
test \"\$remaining\" = '0' && \
test -f '$LIVE_SYNC_SANDBOX/.agents/skills/my-own-skill/SKILL.md'
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

# --agents-md is a deprecated no-op: exits 0, writes nothing
AGENTS_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$AGENTS_SANDBOX")
mkdir -p "$AGENTS_SANDBOX/.codex"
check "sync --agents-md is a no-op (Codex lists skills itself) and writes no AGENTS.md" \
  "
DEWEY_DIR='$REPO_ROOT' CODEX_HOME='$AGENTS_SANDBOX/.codex' HOME='$AGENTS_SANDBOX' \
  bash '$SYNC_SRC' --agents-md '$AGENTS_SANDBOX' >/dev/null 2>&1
test ! -e '$AGENTS_SANDBOX/AGENTS.md'
"

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
test ! -e '$NO_SYNC_SANDBOX/.agents/skills'
test ! -e '$NO_SYNC_SANDBOX/.codex/skills'
"

# The Codex marketplace manifest mirrors the Claude one (see Layer 3 for drift)
check ".agents/plugins/marketplace.json declares every in-tree plugin as a local source" \
  "python3 -c '
import json
c = json.load(open(\"$REPO_ROOT/.agents/plugins/marketplace.json\"))
m = json.load(open(\"$REPO_ROOT/.claude-plugin/marketplace.json\"))
intree = {p[\"name\"] for p in m[\"plugins\"] if isinstance(p[\"source\"], str)}
codex = {p[\"name\"]: p[\"source\"] for p in c[\"plugins\"]}
assert set(codex) == intree, f\"mismatch: {set(codex) ^ intree}\"
for name, src in codex.items():
    assert src[\"source\"] == \"local\" and src[\"path\"].startswith(\"./plugins/\"), name
'"

# docs/codex-sync.md exists and documents the $-invocation
check "docs/codex-sync.md exists and documents \$skill invocation" \
  "test -f '$REPO_ROOT/docs/codex-sync.md' && grep -q 'codex plugin' '$REPO_ROOT/docs/codex-sync.md'"

# ---- Opt-in live test: plugin mode against the real codex CLI ---------------
if [ "${DEWEY_TEST_CODEX_PLUGIN:-0}" = "1" ] && command -v codex >/dev/null 2>&1; then
  PLUGIN_SANDBOX="$(mktemp -d)"
  TMPDIRS_TO_CLEAN+=("$PLUGIN_SANDBOX")
  mkdir -p "$PLUGIN_SANDBOX/.codex"

  check "[live] plugin mode registers the Dewey marketplace and installs plugins into a sandbox CODEX_HOME" \
    "
DEWEY_CODEX_MODE=plugin DEWEY_DIR='$REPO_ROOT' CODEX_HOME='$PLUGIN_SANDBOX/.codex' HOME='$PLUGIN_SANDBOX' \
  bash '$SYNC_SRC' >/dev/null 2>&1
grep -q '^\[marketplaces.dewey\]' '$PLUGIN_SANDBOX/.codex/config.toml'
grep -q 'ops-essentials@dewey' '$PLUGIN_SANDBOX/.codex/config.toml'
test -f '$PLUGIN_SANDBOX/.codex/plugins/cache/dewey/ops-essentials/0.1.0/skills/meeting-prep/SKILL.md'
test -L '$PLUGIN_SANDBOX/.agents/skills/dewey'
"

  check "[live] plugin mode --status reports installed plugins" \
    "
out=\$(DEWEY_CODEX_MODE=plugin DEWEY_DIR='$REPO_ROOT' CODEX_HOME='$PLUGIN_SANDBOX/.codex' HOME='$PLUGIN_SANDBOX' \
  bash '$SYNC_SRC' --status 2>&1)
echo \"\$out\" | grep -q 'missing 0'
"

  check "[live] plugin mode --remove unregisters plugins and the marketplace" \
    "
DEWEY_CODEX_MODE=plugin DEWEY_DIR='$REPO_ROOT' CODEX_HOME='$PLUGIN_SANDBOX/.codex' HOME='$PLUGIN_SANDBOX' \
  bash '$SYNC_SRC' --remove >/dev/null 2>&1
! grep -q '^\[marketplaces.dewey\]' '$PLUGIN_SANDBOX/.codex/config.toml' 2>/dev/null
! grep -q 'ops-essentials@dewey' '$PLUGIN_SANDBOX/.codex/config.toml' 2>/dev/null
"
else
  printf "  %s live Codex plugin-mode tests skipped (set DEWEY_TEST_CODEX_PLUGIN=1 with codex on PATH)\n" "$(yellow ○)"
fi
