# ============================================================================
# LAYER 4: install.sh INTEGRATION (sandbox)
# ============================================================================
section "Layer 4 — install.sh integration (sandboxed)"

SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT

# Pre-populate the sandbox DEWEY_DIR with a non-git copy of our repo, so
# install.sh hits the "exists but not git" branch and uses files in place.
# This avoids needing the repo to be on a real git remote during tests.
SANDBOX_DEWEY="$SANDBOX/.claude/dewey"
mkdir -p "$SANDBOX_DEWEY"
# Copy everything except the tests dir (avoid recursion noise) and .git if present
rsync -a --exclude='tests/' --exclude='.git/' "$REPO_ROOT/" "$SANDBOX_DEWEY/" 2>/dev/null \
  || cp -R "$REPO_ROOT/." "$SANDBOX_DEWEY/"

run_install() {
  HOME="$SANDBOX" \
  DEWEY_DIR="$SANDBOX_DEWEY" \
  DEWEY_REPO="file://$REPO_ROOT" \
  DEWEY_REF="main" \
  DEWEY_USE_INPLACE=1 \
  bash "$REPO_ROOT/install.sh" >"$SANDBOX/install.log" 2>&1
}

check "install.sh runs cleanly in sandbox" \
  "run_install"

check "Guide skill installed at \$HOME/.claude/skills/dewey/SKILL.md" \
  "test -f '$SANDBOX/.claude/skills/dewey/SKILL.md'"

check "installed Guide matches source guide/SKILL.md" \
  "cmp -s '$REPO_ROOT/guide/SKILL.md' '$SANDBOX/.claude/skills/dewey/SKILL.md'"

check "settings.json was created" \
  "test -f '$SANDBOX/.claude/settings.json'"

check "settings.json is valid JSON" \
  "python3 -c 'import json; json.load(open(\"$SANDBOX/.claude/settings.json\"))'"

check "known_marketplaces.json registers dewey marketplace" \
  "python3 -c '
import json
s = json.load(open(\"$SANDBOX/.claude/plugins/known_marketplaces.json\"))
assert \"dewey\" in s
assert s[\"dewey\"][\"source\"][\"source\"] == \"directory\"
'"

check "settings.json has SessionStart hook pointing at first-run script" \
  "python3 -c '
import json
s = json.load(open(\"$SANDBOX/.claude/settings.json\"))
hooks = s.get(\"hooks\", {}).get(\"SessionStart\", [])
assert hooks, \"no SessionStart hooks\"
found = False
for entry in hooks:
    for h in entry.get(\"hooks\", []):
        if \"dewey-first-run.sh\" in h.get(\"command\", \"\"):
            found = True
assert found, \"first-run hook not registered\"
'"

check "first-run hook script created and executable" \
  "test -x '$SANDBOX/.claude/dewey-first-run.sh'"

# Run the first-run hook the FIRST time — should print welcome
check "first-run hook prints welcome on first invocation" \
  "HOME='$SANDBOX' bash '$SANDBOX/.claude/dewey-first-run.sh' | grep -q 'Welcome to Dewey'"

# Marker should now exist
check "first-run marker created after first invocation" \
  "test -f '$SANDBOX/.claude/dewey-onboarded'"

# Run the first-run hook the SECOND time — should be silent
check "first-run hook is silent on second invocation" \
  "out=\$(HOME='$SANDBOX' bash '$SANDBOX/.claude/dewey-first-run.sh'); test -z \"\$out\""

# Idempotency: run install.sh AGAIN. Should not error, should not duplicate hooks.
check "install.sh is idempotent (second run succeeds)" \
  "run_install"

check "settings.json still valid after second install run" \
  "python3 -c 'import json; json.load(open(\"$SANDBOX/.claude/settings.json\"))'"

check "SessionStart hook is not duplicated after second run" \
  "python3 -c '
import json
s = json.load(open(\"$SANDBOX/.claude/settings.json\"))
hooks = s[\"hooks\"][\"SessionStart\"]
matching = 0
for entry in hooks:
    for h in entry.get(\"hooks\", []):
        if \"dewey-first-run.sh\" in h.get(\"command\", \"\"):
            matching += 1
assert matching == 1, f\"expected 1 first-run hook, found {matching}\"
'"

# Pre-existing settings.json with unrelated keys should be preserved
check "install.sh preserves unrelated keys in settings.json" \
  "
SANDBOX2=\$(mktemp -d)
mkdir -p \"\$SANDBOX2/.claude\"
echo '{\"theme\": \"dark\", \"unrelated\": {\"keep\": \"me\"}}' > \"\$SANDBOX2/.claude/settings.json\"
SANDBOX_DEWEY2=\"\$SANDBOX2/.claude/dewey\"
mkdir -p \"\$SANDBOX_DEWEY2\"
cp -R \"$REPO_ROOT/.\" \"\$SANDBOX_DEWEY2/\"
HOME=\"\$SANDBOX2\" DEWEY_DIR=\"\$SANDBOX_DEWEY2\" DEWEY_REPO=\"file://$REPO_ROOT\" DEWEY_REF=main DEWEY_USE_INPLACE=1 bash \"$REPO_ROOT/install.sh\" >/dev/null 2>&1
python3 -c \"
import json
s = json.load(open('\$SANDBOX2/.claude/settings.json'))
assert s.get('theme') == 'dark', 'theme key was lost'
assert s.get('unrelated', {}).get('keep') == 'me', 'unrelated key was lost'
mk = json.load(open('\$SANDBOX2/.claude/plugins/known_marketplaces.json'))
assert 'dewey' in mk, 'dewey marketplace not registered'
\"
rm -rf \"\$SANDBOX2\"
"

# ---- License key tests -------------------------------------------------------

# Install WITH a license key: file should be written mode 600 with exact content.
check "install with DEWEY_LICENSE_KEY writes ~/.claude/dewey-license with correct content" \
  "
SANDBOX_LIC=\$(mktemp -d)
SANDBOX_DEWEY_LIC=\"\$SANDBOX_LIC/.claude/dewey\"
mkdir -p \"\$SANDBOX_DEWEY_LIC\"
cp -R \"$REPO_ROOT/.\" \"\$SANDBOX_DEWEY_LIC/\"
HOME=\"\$SANDBOX_LIC\" \
DEWEY_DIR=\"\$SANDBOX_DEWEY_LIC\" \
DEWEY_REPO=\"file://$REPO_ROOT\" \
DEWEY_REF=main \
DEWEY_USE_INPLACE=1 \
DEWEY_LICENSE_KEY='dwy_aabbccdd11223344aabbccdd11223344' \
  bash \"$REPO_ROOT/install.sh\" >/dev/null 2>&1
test -f \"\$SANDBOX_LIC/.claude/dewey-license\"
actual=\$(cat \"\$SANDBOX_LIC/.claude/dewey-license\")
test \"\$actual\" = 'dwy_aabbccdd11223344aabbccdd11223344'
perms=\$(stat -f '%Lp' \"\$SANDBOX_LIC/.claude/dewey-license\" 2>/dev/null || stat -c '%a' \"\$SANDBOX_LIC/.claude/dewey-license\" 2>/dev/null)
test \"\$perms\" = '600'
rm -rf \"\$SANDBOX_LIC\"
"

# Install WITHOUT a license key: no license file should be created.
check "install without DEWEY_LICENSE_KEY creates no dewey-license file" \
  "
SANDBOX_NOLIC=\$(mktemp -d)
SANDBOX_DEWEY_NOLIC=\"\$SANDBOX_NOLIC/.claude/dewey\"
mkdir -p \"\$SANDBOX_DEWEY_NOLIC\"
cp -R \"$REPO_ROOT/.\" \"\$SANDBOX_DEWEY_NOLIC/\"
HOME=\"\$SANDBOX_NOLIC\" \
DEWEY_DIR=\"\$SANDBOX_DEWEY_NOLIC\" \
DEWEY_REPO=\"file://$REPO_ROOT\" \
DEWEY_REF=main \
DEWEY_USE_INPLACE=1 \
  bash \"$REPO_ROOT/install.sh\" >/dev/null 2>&1
test ! -f \"\$SANDBOX_NOLIC/.claude/dewey-license\"
rm -rf \"\$SANDBOX_NOLIC\"
"

# Install with key but unreachable endpoint: still exits 0 (no license file check).
check "install with key and unreachable endpoint exits 0" \
  "
SANDBOX_UNREACH=\$(mktemp -d)
SANDBOX_DEWEY_UNREACH=\"\$SANDBOX_UNREACH/.claude/dewey\"
mkdir -p \"\$SANDBOX_DEWEY_UNREACH\"
cp -R \"$REPO_ROOT/.\" \"\$SANDBOX_DEWEY_UNREACH/\"
HOME=\"\$SANDBOX_UNREACH\" \
DEWEY_DIR=\"\$SANDBOX_DEWEY_UNREACH\" \
DEWEY_REPO=\"file://$REPO_ROOT\" \
DEWEY_REF=main \
DEWEY_USE_INPLACE=1 \
DEWEY_LICENSE_KEY='dwy_aabbccdd11223344aabbccdd11223344' \
DEWEY_TELEMETRY_ENDPOINT='http://127.0.0.1:19999' \
  bash \"$REPO_ROOT/install.sh\" >/dev/null 2>&1
test -f \"\$SANDBOX_UNREACH/.claude/dewey-license\"
rm -rf \"\$SANDBOX_UNREACH\"
"

# No-license no-degradation: emit + normal install + forward all exit 0.
check "no-license no-degradation: emit + install + forward all exit 0" \
  "
SANDBOX_NODEG=\$(mktemp -d)
SANDBOX_DEWEY_NODEG=\"\$SANDBOX_NODEG/.claude/dewey\"
mkdir -p \"\$SANDBOX_DEWEY_NODEG\"
cp -R \"$REPO_ROOT/.\" \"\$SANDBOX_DEWEY_NODEG/\"
# Normal install with no license
HOME=\"\$SANDBOX_NODEG\" \
DEWEY_DIR=\"\$SANDBOX_DEWEY_NODEG\" \
DEWEY_REPO=\"file://$REPO_ROOT\" \
DEWEY_REF=main \
DEWEY_USE_INPLACE=1 \
  bash \"$REPO_ROOT/install.sh\" >/dev/null 2>&1
# Emit an event
DEWEY_DIR=\"\$SANDBOX_DEWEY_NODEG\" \
DEWEY_LOG=\"\$SANDBOX_NODEG/.claude/dewey-analytics.log\" \
  bash \"$REPO_ROOT/dewey-telemetry.sh\" emit event=test_no_lic
# Forward (no endpoint, no license) → exit 0 silently
DEWEY_DIR=\"\$SANDBOX_DEWEY_NODEG\" \
DEWEY_LOG=\"\$SANDBOX_NODEG/.claude/dewey-analytics.log\" \
HOME=\"\$SANDBOX_NODEG\" \
DEWEY_TELEMETRY_ENDPOINT='' \
  bash \"$REPO_ROOT/dewey-telemetry.sh\" forward
rm -rf \"\$SANDBOX_NODEG\"
"
