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
