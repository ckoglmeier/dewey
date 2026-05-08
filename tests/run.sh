#!/usr/bin/env bash
# Dewey v1 test suite
#
# Runs three layers of checks:
#   1. Static/structural — JSON validity, schema, file presence
#   2. Cross-reference   — paths only reference real plugins, marketplace points at real dirs
#   3. install.sh        — sandbox-run the installer, verify state, idempotency, hook behavior
#
# Usage:  bash tests/run.sh
# Exit:   0 if all tests pass, 1 if any failed.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# ---- Test framework ---------------------------------------------------------
PASSED=0
FAILED=0
FAILED_NAMES=()

red()    { printf "\033[1;31m%s\033[0m" "$*"; }
green()  { printf "\033[1;32m%s\033[0m" "$*"; }
yellow() { printf "\033[1;33m%s\033[0m" "$*"; }
bold()   { printf "\033[1m%s\033[0m" "$*"; }

pass() {
  PASSED=$((PASSED + 1))
  printf "  %s %s\n" "$(green ✓)" "$1"
}

fail() {
  FAILED=$((FAILED + 1))
  FAILED_NAMES+=("$1")
  printf "  %s %s\n" "$(red ✗)" "$1"
  if [ -n "${2:-}" ]; then
    printf "      %s\n" "$2"
  fi
}

section() {
  printf "\n%s\n" "$(bold "$1")"
}

# Run a check: $1 = name, $2 = command (eval'd). Pass if exit 0.
check() {
  local name="$1"
  local cmd="$2"
  local out
  if out=$(eval "$cmd" 2>&1); then
    pass "$name"
  else
    fail "$name" "${out:-(no output)}"
  fi
}

# ============================================================================
# LAYER 1: STATIC / STRUCTURAL
# ============================================================================
section "Layer 1 — Static / structural checks"

check "marketplace.json exists" \
  "test -f .claude-plugin/marketplace.json"

check "marketplace.json is valid JSON" \
  "python3 -c 'import json; json.load(open(\".claude-plugin/marketplace.json\"))'"

check "marketplace.json has required fields (name, owner, plugins)" \
  "python3 -c '
import json, sys
m = json.load(open(\".claude-plugin/marketplace.json\"))
for f in (\"name\", \"owner\", \"plugins\"):
    assert f in m, f\"missing field: {f}\"
assert isinstance(m[\"plugins\"], list) and len(m[\"plugins\"]) > 0, \"plugins must be a non-empty list\"
assert \"name\" in m[\"owner\"], \"owner.name required\"
'"

check "marketplace name is kebab-case" \
  "python3 -c '
import json, re
m = json.load(open(\".claude-plugin/marketplace.json\"))
name = m[\"name\"]
assert re.fullmatch(r\"[a-z0-9]+(-[a-z0-9]+)*\", name), \"not kebab-case: \" + name
'"

# Check each plugin entry in marketplace.json
check "every plugin entry has name + source" \
  "python3 -c '
import json
m = json.load(open(\".claude-plugin/marketplace.json\"))
for p in m[\"plugins\"]:
    assert \"name\" in p, \"plugin missing name: \" + repr(p)
    assert \"source\" in p, \"plugin missing source: \" + repr(p)
'"

# Each plugin's plugin.json must exist and be valid
for plugin_dir in plugins/*/; do
  plugin_name=$(basename "$plugin_dir")
  manifest="$plugin_dir.claude-plugin/plugin.json"

  check "[$plugin_name] plugin.json exists" \
    "test -f '$manifest'"

  check "[$plugin_name] plugin.json is valid JSON" \
    "python3 -c 'import json; json.load(open(\"$manifest\"))'"

  check "[$plugin_name] plugin.json has name + description + version" \
    "python3 -c '
import json
p = json.load(open(\"$manifest\"))
for f in (\"name\", \"description\", \"version\"):
    assert f in p, \"missing \" + f
'"

  check "[$plugin_name] plugin.json name matches directory name" \
    "python3 -c '
import json
p = json.load(open(\"$manifest\"))
expected = \"$plugin_name\"
assert p[\"name\"] == expected, \"name \" + p[\"name\"] + \" != dir \" + expected
'"

  check "[$plugin_name] has at least one skill" \
    "test -d '$plugin_dir/skills' && test -n \"\$(ls -A '$plugin_dir/skills' 2>/dev/null)\""
done

# Guide skill present
check "guide/SKILL.md exists" \
  "test -f guide/SKILL.md"

check "install.sh exists and is executable" \
  "test -x install.sh"

check "install.sh has clean bash syntax" \
  "bash -n install.sh"

check "README.md exists" \
  "test -f README.md"

check "docs/extending-skills.md exists" \
  "test -f docs/extending-skills.md"

check "docs/path-files.md exists" \
  "test -f docs/path-files.md"

check "docs/pr-checklist.md exists" \
  "test -f docs/pr-checklist.md"

# ============================================================================
# LAYER 2: SKILL FRONTMATTER
# ============================================================================
section "Layer 2 — Skill frontmatter checks"

# All SKILL.md files (plugins + guide). bash 3.2 compatible (no mapfile).
SKILL_FILES=()
while IFS= read -r line; do
  SKILL_FILES+=("$line")
done < <(find guide plugins -name 'SKILL.md' | sort)

check "found at least 1 skill file" \
  "test ${#SKILL_FILES[@]} -gt 0"

for skill in "${SKILL_FILES[@]}"; do
  rel="${skill#./}"

  check "[$rel] starts with --- frontmatter delimiter" \
    "head -1 '$skill' | grep -q '^---$'"

  # Parse the YAML frontmatter via python (no PyYAML — use a tiny manual parser)
  check "[$rel] has parseable frontmatter with description" \
    "python3 -c '
import sys, re
text = open(\"$skill\").read()
m = re.match(r\"^---\n(.*?)\n---\n\", text, re.DOTALL)
assert m, \"no frontmatter block found\"
fm = m.group(1)
fields = {}
for line in fm.splitlines():
    if \":\" in line and not line.startswith(\" \"):
        k, _, v = line.partition(\":\")
        fields[k.strip()] = v.strip().strip(\"\\\"\").strip(\"'\\''\")
assert \"description\" in fields, \"missing required: description\"
desc = fields[\"description\"]
assert len(desc) > 0, \"description is empty\"
'"

  check "[$rel] description under 250 chars (truncation safe)" \
    "python3 -c '
import re
text = open(\"$skill\").read()
m = re.match(r\"^---\n(.*?)\n---\n\", text, re.DOTALL)
fm = m.group(1)
for line in fm.splitlines():
    if line.startswith(\"description:\"):
        desc = line.split(\":\", 1)[1].strip().strip(chr(34)).strip(chr(39))
        assert len(desc) <= 250, \"description \" + str(len(desc)) + \" > 250\"
        break
'"

  check "[$rel] name field (if present) is kebab-case ≤64 chars" \
    "python3 -c '
import re
text = open(\"$skill\").read()
m = re.match(r\"^---\n(.*?)\n---\n\", text, re.DOTALL)
fm = m.group(1)
for line in fm.splitlines():
    if line.startswith(\"name:\"):
        name = line.split(\":\", 1)[1].strip().strip(chr(34)).strip(chr(39))
        assert re.fullmatch(r\"[a-z0-9]+(-[a-z0-9]+)*\", name), \"not kebab-case: \" + name
        assert len(name) <= 64, \"too long: \" + str(len(name))
        break
'"

  check "[$rel] body has non-trivial content (>200 chars after frontmatter)" \
    "python3 -c '
import re
text = open(\"$skill\").read()
body = re.sub(r\"^---\n.*?\n---\n\", \"\", text, count=1, flags=re.DOTALL)
stripped = body.strip()
assert len(stripped) > 200, \"body only \" + str(len(stripped)) + \" chars\"
'"
done

# ============================================================================
# LAYER 3: CROSS-REFERENCE
# ============================================================================
section "Layer 3 — Cross-reference checks"

check "every marketplace plugin source path resolves to a real dir" \
  "python3 -c '
import json, os
m = json.load(open(\".claude-plugin/marketplace.json\"))
for p in m[\"plugins\"]:
    src = p[\"source\"]
    if isinstance(src, str) and src.startswith(\"./\"):
        path = src[2:]
        assert os.path.isdir(path), \"missing dir: \" + path + \" for plugin \" + p[\"name\"]
'"

check "every marketplace plugin has a matching plugin.json with same name" \
  "python3 -c '
import json, os
m = json.load(open(\".claude-plugin/marketplace.json\"))
for p in m[\"plugins\"]:
    src = p[\"source\"]
    if isinstance(src, str) and src.startswith(\"./\"):
        manifest = os.path.join(src[2:], \".claude-plugin\", \"plugin.json\")
        assert os.path.isfile(manifest), \"missing manifest: \" + manifest
        pj = json.load(open(manifest))
        assert pj[\"name\"] == p[\"name\"], \"name mismatch: marketplace=\" + p[\"name\"] + \" manifest=\" + pj[\"name\"]
'"

check "every disk plugin is listed in marketplace.json" \
  "python3 -c '
import json, os
m = json.load(open(\".claude-plugin/marketplace.json\"))
listed = set(p[\"name\"] for p in m[\"plugins\"])
on_disk = set(os.listdir(\"plugins\"))
missing = on_disk - listed
assert not missing, \"plugins on disk but not in marketplace: \" + repr(missing)
'"

# ----------------------------------------------------------------------------
# Layer 3b: external source schema checks
# ----------------------------------------------------------------------------
# For any plugin whose \"source\" is an object (not a \"./\" string), validate
# the schema so we catch typos and missing pins at test time. Live resolution
# against the remote is a follow-up (opt-in Layer 8, not yet implemented).

check "external plugin sources declare a source type accepted by 'claude plugin marketplace add'" \
  "python3 -c '
import json
m = json.load(open(\".claude-plugin/marketplace.json\"))
# Verified accepted by Claude Code v2.1.47: github, url, npm.
# Verified rejected: git, git-subdir (the latter was grandfathered for the
# official marketplace and is no longer accepted for new ones).
# See docs/decisions/external-plugin-distribution.md.
ACCEPTED = {\"github\", \"url\", \"npm\"}
for p in m[\"plugins\"]:
    src = p[\"source\"]
    if isinstance(src, dict):
        t = src.get(\"source\")
        assert t in ACCEPTED, p[\"name\"] + \": source type \" + repr(t) + \" is not accepted by claude plugin marketplace add (use one of \" + str(sorted(ACCEPTED)) + \")\"
'"

check "external github sources have repo (ref/sha optional)" \
  "python3 -c '
import json
m = json.load(open(\".claude-plugin/marketplace.json\"))
for p in m[\"plugins\"]:
    src = p[\"source\"]
    if isinstance(src, dict) and src.get(\"source\") == \"github\":
        assert src.get(\"repo\"), p[\"name\"] + \": github source missing repo\"
'"

check "external url sources have url + (ref or sha)" \
  "python3 -c '
import json
m = json.load(open(\".claude-plugin/marketplace.json\"))
for p in m[\"plugins\"]:
    src = p[\"source\"]
    if isinstance(src, dict) and src.get(\"source\") == \"url\":
        assert src.get(\"url\"), p[\"name\"] + \": url source missing url\"
        assert src.get(\"ref\") or src.get(\"sha\"), p[\"name\"] + \": url needs ref or sha\"
'"

check "external npm sources have package" \
  "python3 -c '
import json
m = json.load(open(\".claude-plugin/marketplace.json\"))
for p in m[\"plugins\"]:
    src = p[\"source\"]
    if isinstance(src, dict) and src.get(\"source\") == \"npm\":
        assert src.get(\"package\"), p[\"name\"] + \": npm source missing package\"
'"

# Path files reference only plugins that exist
check "paths/sales-ae.md only references real plugin names" \
  "python3 -c '
import json, re
m = json.load(open(\".claude-plugin/marketplace.json\"))
known = set(p[\"name\"] for p in m[\"plugins\"])
text = open(\"paths/sales-ae.md\").read()
referenced = set(re.findall(r\"\\*\\*([a-z0-9]+(?:-[a-z0-9]+)*)\\*\\*\", text))
candidates = set(r for r in referenced if \"-\" in r)
unknown = candidates - known
assert not unknown, \"references unknown plugins: \" + repr(unknown)
'"

check "paths/ops-analyst.md only references real plugin names" \
  "python3 -c '
import json, re
m = json.load(open(\".claude-plugin/marketplace.json\"))
known = set(p[\"name\"] for p in m[\"plugins\"])
text = open(\"paths/ops-analyst.md\").read()
referenced = set(re.findall(r\"\\*\\*([a-z0-9]+(?:-[a-z0-9]+)*)\\*\\*\", text))
candidates = set(r for r in referenced if \"-\" in r)
unknown = candidates - known
assert not unknown, \"references unknown plugins: \" + repr(unknown)
'"

# Guide skill name should be 'dewey' since /dewey is the entry point
check "guide skill name is dewey (matches /dewey slash command)" \
  "python3 -c '
import re
text = open(\"guide/SKILL.md\").read()
m = re.match(r\"^---\n(.*?)\n---\n\", text, re.DOTALL)
fm = m.group(1)
found_name = None
for line in fm.splitlines():
    if line.startswith(\"name:\"):
        found_name = line.split(\":\", 1)[1].strip()
        break
assert found_name == \"dewey\", \"guide name is \" + repr(found_name) + \", expected dewey\"
'"

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

# ============================================================================
# LAYER 4b: CLASSROOM → DEWEY MIGRATION (sandbox)
# ============================================================================
# v2.0 install must hard-rename a prior Classroom install to Dewey:
# - ~/.claude/classroom/ → ~/.claude/dewey/
# - ~/.claude/skills/classroom/ → ~/.claude/skills/dewey/
# - ~/.claude/classroom-*.sh → removed (replaced by dewey-* helpers)
# - ~/.claude/classroom-{onboarded,first-run.sh,refresh.sh,...} → dewey-* equivalents
# - ~/.claude/classroom-analytics.log → ~/.claude/dewey-analytics.log (history preserved)
# - known_marketplaces.json: "classroom" key → "dewey", with paths updated
section "Layer 4b — Classroom→Dewey migration"

MIG_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$MIG_SANDBOX")
mkdir -p "$MIG_SANDBOX/.claude/skills/classroom" \
         "$MIG_SANDBOX/.claude/classroom" \
         "$MIG_SANDBOX/.claude/plugins"

# Pre-seed a fake old Classroom install
echo "old-cache-marker" > "$MIG_SANDBOX/.claude/classroom/marker"
echo "old-guide-content" > "$MIG_SANDBOX/.claude/skills/classroom/SKILL.md"
echo "old-analytics-line" > "$MIG_SANDBOX/.claude/classroom-analytics.log"
touch "$MIG_SANDBOX/.claude/classroom-onboarded"
echo "stub" > "$MIG_SANDBOX/.claude/classroom-refresh.sh"
echo "stub" > "$MIG_SANDBOX/.claude/classroom-propose.sh"
cat > "$MIG_SANDBOX/.claude/plugins/known_marketplaces.json" <<EOF
{
  "classroom": {
    "source": {"source": "directory", "path": "$MIG_SANDBOX/.claude/classroom"},
    "installLocation": "$MIG_SANDBOX/.claude/classroom",
    "lastUpdated": "2026-04-01T00:00:00Z"
  }
}
EOF

# Run install — should detect old paths and migrate
HOME="$MIG_SANDBOX" DEWEY_REPO="file://$REPO_ROOT" DEWEY_REF=main DEWEY_USE_INPLACE=1 \
  DEWEY_DIR="$MIG_SANDBOX/.claude/dewey" \
  bash "$REPO_ROOT/install.sh" >/dev/null 2>&1 || true

# But DEWEY_USE_INPLACE=1 means it won't fetch — for migration test we want the migration to run
# even when the cache itself is newly-arriving. Use the tarball path:
TARBALL_FILE2="$(mktemp -t dewey-mig.XXXXXX.tar.gz)"
TMPDIRS_TO_CLEAN+=("$(dirname "$TARBALL_FILE2")")
TARBALL_DIR2="$(mktemp -d)"
mkdir -p "$TARBALL_DIR2/stage/dewey-snapshot"
if command -v rsync >/dev/null 2>&1; then
  rsync -a --exclude='tests/' --exclude='.git/' "$REPO_ROOT/" "$TARBALL_DIR2/stage/dewey-snapshot/" 2>/dev/null
else
  cp -R "$REPO_ROOT/." "$TARBALL_DIR2/stage/dewey-snapshot/"
  rm -rf "$TARBALL_DIR2/stage/dewey-snapshot/tests" "$TARBALL_DIR2/stage/dewey-snapshot/.git"
fi
( cd "$TARBALL_DIR2/stage" && tar -czf "$TARBALL_FILE2" dewey-snapshot )
TMPDIRS_TO_CLEAN+=("$TARBALL_DIR2")

# Reset sandbox state for a clean run
rm -rf "$MIG_SANDBOX"
mkdir -p "$MIG_SANDBOX/.claude/skills/classroom" \
         "$MIG_SANDBOX/.claude/classroom" \
         "$MIG_SANDBOX/.claude/plugins"
echo "old-cache-marker" > "$MIG_SANDBOX/.claude/classroom/marker"
echo "old-guide-content" > "$MIG_SANDBOX/.claude/skills/classroom/SKILL.md"
echo "old-analytics-line" > "$MIG_SANDBOX/.claude/classroom-analytics.log"
touch "$MIG_SANDBOX/.claude/classroom-onboarded"
echo "stub" > "$MIG_SANDBOX/.claude/classroom-refresh.sh"
echo "stub" > "$MIG_SANDBOX/.claude/classroom-propose.sh"
cat > "$MIG_SANDBOX/.claude/plugins/known_marketplaces.json" <<EOF
{
  "classroom": {
    "source": {"source": "directory", "path": "$MIG_SANDBOX/.claude/classroom"},
    "installLocation": "$MIG_SANDBOX/.claude/classroom",
    "lastUpdated": "2026-04-01T00:00:00Z"
  }
}
EOF

HOME="$MIG_SANDBOX" DEWEY_REPO="$REPO_ROOT" DEWEY_REF=main DEWEY_TARBALL="file://$TARBALL_FILE2" \
  bash "$REPO_ROOT/install.sh" >/dev/null 2>&1

check "migration: ~/.claude/classroom/ renamed to ~/.claude/dewey/" \
  "test ! -e '$MIG_SANDBOX/.claude/classroom' && test -d '$MIG_SANDBOX/.claude/dewey'"

check "migration: ~/.claude/skills/classroom/ renamed to ~/.claude/skills/dewey/" \
  "test ! -e '$MIG_SANDBOX/.claude/skills/classroom' && test -d '$MIG_SANDBOX/.claude/skills/dewey'"

check "migration: classroom-analytics.log renamed to dewey-analytics.log (content preserved)" \
  "test ! -e '$MIG_SANDBOX/.claude/classroom-analytics.log' && \
   grep -q 'old-analytics-line' '$MIG_SANDBOX/.claude/dewey-analytics.log'"

check "migration: classroom-onboarded renamed to dewey-onboarded" \
  "test ! -e '$MIG_SANDBOX/.claude/classroom-onboarded' && test -e '$MIG_SANDBOX/.claude/dewey-onboarded'"

check "migration: old classroom-*.sh helpers removed" \
  "test ! -e '$MIG_SANDBOX/.claude/classroom-propose.sh' && \
   test ! -e '$MIG_SANDBOX/.claude/classroom-refresh.sh'"

check "migration: known_marketplaces.json 'classroom' key renamed to 'dewey'" \
  "python3 -c '
import json
d = json.load(open(\"$MIG_SANDBOX/.claude/plugins/known_marketplaces.json\"))
assert \"classroom\" not in d, \"classroom key still present\"
assert \"dewey\" in d, \"dewey key missing\"
loc = d[\"dewey\"][\"installLocation\"]
assert loc.endswith(\"/.claude/dewey\"), \"installLocation not migrated: \" + loc
'"

check "migration: dewey-migration.log records what was migrated" \
  "test -f '$MIG_SANDBOX/.claude/dewey-migration.log' && \
   grep -q 'classroom' '$MIG_SANDBOX/.claude/dewey-migration.log'"

# Idempotency: run install again; nothing more to migrate
HOME="$MIG_SANDBOX" DEWEY_REPO="$REPO_ROOT" DEWEY_REF=main DEWEY_TARBALL="file://$TARBALL_FILE2" \
  bash "$REPO_ROOT/install.sh" >/dev/null 2>&1

check "migration: re-running install is idempotent (no classroom paths reappear)" \
  "test ! -e '$MIG_SANDBOX/.claude/classroom' && \
   test ! -e '$MIG_SANDBOX/.claude/skills/classroom' && \
   test ! -e '$MIG_SANDBOX/.claude/classroom-analytics.log'"

# ============================================================================
# LAYER 5: OWNERSHIP (plugin.json author field + CODEOWNERS)
# ============================================================================
section "Layer 5 — Ownership"

check "CODEOWNERS exists at repo root" \
  "test -f CODEOWNERS"

# Every plugin.json must declare an author with name + contact
for plugin_dir in plugins/*/; do
  plugin_name=$(basename "$plugin_dir")
  manifest="$plugin_dir.claude-plugin/plugin.json"

  check "[$plugin_name] plugin.json has author.name and author.contact" \
    "python3 -c '
import json
p = json.load(open(\"$manifest\"))
assert \"author\" in p, \"missing author field\"
o = p[\"author\"]
assert isinstance(o, dict), \"author must be an object\"
assert o.get(\"name\"), \"author.name required\"
assert o.get(\"contact\"), \"author.contact required\"
'"

  check "[$plugin_name] CODEOWNERS has a line for plugins/$plugin_name/" \
    "grep -q '^/plugins/$plugin_name/' CODEOWNERS"
done

# ============================================================================
# LAYER 6: TARBALL INSTALL PATH (no git, atomic swap, checksum, guard)
# ============================================================================
section "Layer 6 — Tarball install path"

# Build a local tarball that mimics the GitHub /archive/<ref>.tar.gz layout
# (single top-level dir; we use --strip-components=1 to remove it on extract).
TARBALL_DIR="$(mktemp -d)"
TMPDIRS_TO_CLEAN=("$SANDBOX" "$TARBALL_DIR")
cleanup_tmpdirs() {
  for d in "${TMPDIRS_TO_CLEAN[@]}"; do
    [ -n "$d" ] && [ -d "$d" ] && rm -rf "$d"
  done
}
trap cleanup_tmpdirs EXIT

# Stage repo contents under a single parent dir, excluding tests/ (avoid recursion)
# and .git/. We then tar that single parent so --strip-components=1 cleanly removes it.
mkdir -p "$TARBALL_DIR/stage/dewey-snapshot"
if command -v rsync >/dev/null 2>&1; then
  rsync -a --exclude='tests/' --exclude='.git/' "$REPO_ROOT/" "$TARBALL_DIR/stage/dewey-snapshot/" 2>/dev/null
else
  cp -R "$REPO_ROOT/." "$TARBALL_DIR/stage/dewey-snapshot/"
  rm -rf "$TARBALL_DIR/stage/dewey-snapshot/tests" "$TARBALL_DIR/stage/dewey-snapshot/.git"
fi

TARBALL_FILE="$TARBALL_DIR/dewey.tar.gz"
( cd "$TARBALL_DIR/stage" && tar -czf "$TARBALL_FILE" dewey-snapshot )

check "test tarball was built" \
  "test -s '$TARBALL_FILE'"

TARBALL_SHA=$(shasum -a 256 "$TARBALL_FILE" | awk '{print $1}')

# Fresh sandbox with NO pre-populated DEWEY_DIR — install must download.
TARBALL_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$TARBALL_SANDBOX")
TARBALL_SANDBOX_DEWEY="$TARBALL_SANDBOX/.claude/dewey"

run_tarball_install() {
  HOME="$TARBALL_SANDBOX" \
  DEWEY_DIR="$TARBALL_SANDBOX_DEWEY" \
  DEWEY_REPO="https://example.invalid/dewey" \
  DEWEY_REF="main" \
  DEWEY_TARBALL="file://$TARBALL_FILE" \
  bash "$REPO_ROOT/install.sh" >"$TARBALL_SANDBOX/install.log" 2>&1
}

check "install.sh runs cleanly via tarball (no git)" \
  "run_tarball_install"

check "tarball install populated guide/SKILL.md" \
  "test -f '$TARBALL_SANDBOX_DEWEY/guide/SKILL.md'"

check "tarball install populated marketplace.json" \
  "test -f '$TARBALL_SANDBOX_DEWEY/.claude-plugin/marketplace.json'"

check "tarball install installed Guide as personal skill" \
  "test -f '$TARBALL_SANDBOX/.claude/skills/dewey/SKILL.md'"

check "tarball install left no .old or .new sibling dirs" \
  "test ! -e '$TARBALL_SANDBOX_DEWEY.new' && ! ls -d '$TARBALL_SANDBOX_DEWEY'.old.* >/dev/null 2>&1"

check "tarball install registered the marketplace in known_marketplaces.json" \
  "python3 -c '
import json
s = json.load(open(\"$TARBALL_SANDBOX/.claude/plugins/known_marketplaces.json\"))
assert \"dewey\" in s
assert s[\"dewey\"][\"source\"][\"source\"] == \"directory\"
'"

check "tarball install dropped a refresh script" \
  "test -x '$TARBALL_SANDBOX/.claude/dewey-refresh.sh'"

# Idempotent re-run via tarball
check "tarball install is idempotent" \
  "run_tarball_install"

check "second tarball run still left no stale .old.* dirs" \
  "test ! -e '$TARBALL_SANDBOX_DEWEY.new' && ! ls -d '$TARBALL_SANDBOX_DEWEY'.old.* >/dev/null 2>&1"

# ---- Checksum verification --------------------------------------------------

# Pass: correct SHA
TARBALL_SANDBOX_OK="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$TARBALL_SANDBOX_OK")
check "tarball install passes with matching DEWEY_TARBALL_SHA256" \
  "HOME='$TARBALL_SANDBOX_OK' DEWEY_DIR='$TARBALL_SANDBOX_OK/.claude/dewey' DEWEY_TARBALL='file://$TARBALL_FILE' DEWEY_TARBALL_SHA256='$TARBALL_SHA' bash '$REPO_ROOT/install.sh' >/dev/null 2>&1"

# Fail: wrong SHA, must abort and leave DEWEY_DIR untouched
TARBALL_SANDBOX_BAD="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$TARBALL_SANDBOX_BAD")
check "tarball install aborts on bad DEWEY_TARBALL_SHA256" \
  "HOME='$TARBALL_SANDBOX_BAD' DEWEY_DIR='$TARBALL_SANDBOX_BAD/.claude/dewey' DEWEY_TARBALL='file://$TARBALL_FILE' DEWEY_TARBALL_SHA256='0000000000000000000000000000000000000000000000000000000000000000' bash '$REPO_ROOT/install.sh' >/dev/null 2>&1; test \$? -ne 0"

check "bad-checksum run did NOT populate DEWEY_DIR" \
  "test ! -f '$TARBALL_SANDBOX_BAD/.claude/dewey/guide/SKILL.md'"

# ---- Destructive-path guard -------------------------------------------------

# DEWEY_DIR that doesn't end in .claude/dewey must be refused.
GUARD_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$GUARD_SANDBOX")
mkdir -p "$GUARD_SANDBOX/somewhere-else"
echo "do not delete me" > "$GUARD_SANDBOX/somewhere-else/canary.txt"
check "install.sh refuses DEWEY_DIR that doesn't end in .claude/dewey" \
  "HOME='$GUARD_SANDBOX' DEWEY_DIR='$GUARD_SANDBOX/somewhere-else' DEWEY_TARBALL='file://$TARBALL_FILE' bash '$REPO_ROOT/install.sh' >/dev/null 2>&1; test \$? -ne 0"

check "guard left the canary file untouched" \
  "test -f '$GUARD_SANDBOX/somewhere-else/canary.txt'"

# ---- No git on PATH ---------------------------------------------------------

# Build a stripped PATH dir that excludes git but includes essentials.
STRIP_DIR="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$STRIP_DIR")
for tool in bash sh curl tar shasum python3 mktemp dirname rm mv mkdir cp ls cat date stat awk sed grep printf chmod cmp basename head touch find file; do
  src="$(command -v "$tool" 2>/dev/null || true)"
  if [ -n "$src" ]; then
    ln -sf "$src" "$STRIP_DIR/$tool" 2>/dev/null || true
  fi
done
NOGIT_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$NOGIT_SANDBOX")
check "install.sh runs with git absent from PATH" \
  "PATH='$STRIP_DIR' HOME='$NOGIT_SANDBOX' DEWEY_DIR='$NOGIT_SANDBOX/.claude/dewey' DEWEY_TARBALL='file://$TARBALL_FILE' bash '$REPO_ROOT/install.sh' >/dev/null 2>&1"

check "no-git install populated guide/SKILL.md" \
  "test -f '$NOGIT_SANDBOX/.claude/dewey/guide/SKILL.md'"

# ============================================================================
# LAYER 7: REFRESH SCRIPT
# ============================================================================
section "Layer 7 — Refresh script"

# Use the tarball sandbox from Layer 6 which has a refresh.sh installed.
REFRESH="$TARBALL_SANDBOX/.claude/dewey-refresh.sh"

check "refresh.sh exists and is executable" \
  "test -x '$REFRESH'"

# Force interval=0 so the marker doesn't gate the test, point at our local tarball.
run_refresh() {
  HOME="$TARBALL_SANDBOX" \
  DEWEY_DIR="$TARBALL_SANDBOX_DEWEY" \
  DEWEY_TARBALL="file://$TARBALL_FILE" \
  DEWEY_REFRESH_INTERVAL=0 \
  bash "$REFRESH"
}

check "refresh.sh runs cleanly when forced" \
  "run_refresh"

check "refresh.sh wrote a last-refresh marker" \
  "test -f '$TARBALL_SANDBOX/.claude/dewey-last-refresh'"

check "refresh.sh wrote a log entry" \
  "test -s '$TARBALL_SANDBOX/.claude/dewey-refresh.log'"

check "refresh.sh left no stale .old.* dirs" \
  "test ! -e '$TARBALL_SANDBOX_DEWEY.new' && ! ls -d '$TARBALL_SANDBOX_DEWEY'.old.* >/dev/null 2>&1"

# Lock-file blocks concurrent execution.
check "refresh.sh exits silently when lock file exists" \
  "
touch '$TARBALL_SANDBOX/.claude/dewey-refresh.lock'
HOME='$TARBALL_SANDBOX' DEWEY_DIR='$TARBALL_SANDBOX_DEWEY' DEWEY_TARBALL='file://$TARBALL_FILE' DEWEY_REFRESH_INTERVAL=0 bash '$REFRESH'
test \$? -eq 0
test -f '$TARBALL_SANDBOX/.claude/dewey-refresh.lock'
rm -f '$TARBALL_SANDBOX/.claude/dewey-refresh.lock'
"

# 24h marker honored: with default interval and a fresh marker, refresh should be a no-op.
check "refresh.sh skips when marker is fresh and interval is default" \
  "
touch '$TARBALL_SANDBOX/.claude/dewey-last-refresh'
out=\$(HOME='$TARBALL_SANDBOX' DEWEY_DIR='$TARBALL_SANDBOX_DEWEY' DEWEY_TARBALL='file://$TARBALL_FILE' bash '$REFRESH' 2>&1)
test -z \"\$out\"
"

# Disabled when interval is -1.
check "refresh.sh disabled with DEWEY_REFRESH_INTERVAL=-1" \
  "HOME='$TARBALL_SANDBOX' DEWEY_DIR='$TARBALL_SANDBOX_DEWEY' DEWEY_TARBALL='file://$TARBALL_FILE' DEWEY_REFRESH_INTERVAL=-1 bash '$REFRESH'"

# Network/extract failure must not break the cache or exit non-zero.
NETFAIL_LOG="$TARBALL_SANDBOX/.claude/dewey-refresh.log"
NETFAIL_BEFORE=$(wc -c < "$NETFAIL_LOG" 2>/dev/null || echo 0)
check "refresh.sh exits 0 on network failure (bad URL)" \
  "HOME='$TARBALL_SANDBOX' DEWEY_DIR='$TARBALL_SANDBOX_DEWEY' DEWEY_TARBALL='file:///nonexistent/path/that/does/not/exist.tar.gz' DEWEY_REFRESH_INTERVAL=0 bash '$REFRESH'"

check "refresh.sh logged the network failure" \
  "test \$(wc -c < '$NETFAIL_LOG') -gt $NETFAIL_BEFORE"

check "refresh.sh did NOT damage DEWEY_DIR after network failure" \
  "test -f '$TARBALL_SANDBOX_DEWEY/guide/SKILL.md'"

# Dev-checkout no-op: with .git/ present, refresh exits silently.
mkdir -p "$TARBALL_SANDBOX_DEWEY/.git"
check "refresh.sh is a no-op when DEWEY_DIR/.git exists" \
  "
out=\$(HOME='$TARBALL_SANDBOX' DEWEY_DIR='$TARBALL_SANDBOX_DEWEY' DEWEY_TARBALL='file://$TARBALL_FILE' DEWEY_REFRESH_INTERVAL=0 bash '$REFRESH' 2>&1)
test -z \"\$out\"
"
rm -rf "$TARBALL_SANDBOX_DEWEY/.git"

# ============================================================================
# LAYER 8: LIVE EXTERNAL ENTRY VALIDATION (opt-in)
# ============================================================================
# Network-dependent. Off by default; gated by DEWEY_VALIDATE_EXTERNAL=1.
# For each external entry in marketplace.json (object source), actually fetches
# the upstream and confirms it resolves to a valid plugin. Catches the failure
# class that schema-only lint can't see — entry passes Layer 3b but install
# would produce a broken plugin.
section "Layer 8 — Live external entry validation (opt-in)"

if [ "${DEWEY_VALIDATE_EXTERNAL:-0}" != "1" ]; then
  printf "  (skipped — set DEWEY_VALIDATE_EXTERNAL=1 to enable)\n"
else
  # Iterate every external entry; one check per entry.
  while IFS= read -r entry_json; do
    [ -z "$entry_json" ] && continue
    entry_name=$(printf '%s' "$entry_json" | python3 -c "import json, sys; print(json.loads(sys.stdin.read())['name'])")
    check "[$entry_name] external entry fetches and resolves to a valid plugin" \
      "python3 '$REPO_ROOT/tests/lib/validate_external_entry.py' '$entry_json'"
  done < <(python3 -c '
import json
m = json.load(open(".claude-plugin/marketplace.json"))
for p in m["plugins"]:
    if isinstance(p["source"], dict):
        print(json.dumps(p))
')

  # Self-test: run the validator against a known-bad fixture entry to prove
  # the validator catches errors. Uses a deliberately nonexistent github repo.
  check "[self-test] validator rejects a nonexistent github repo" \
    "
out=\$(python3 '$REPO_ROOT/tests/lib/validate_external_entry.py' \
      '{\"name\":\"x\",\"source\":{\"source\":\"github\",\"repo\":\"ckoglmeier/this-does-not-exist-dewey-test\"}}' 2>&1)
echo \"\$out\" | grep -qi 'not found'
"
fi

# ============================================================================
# LAYER 9: ANALYTICS LOG
# ============================================================================
section "Layer 9 — Analytics log"

check "install.sh creates dewey-analytics.log when DEWEY_TELEMETRY != 0" \
  "test -f '$SANDBOX/.claude/dewey-analytics.log'"

check "dewey-analytics.log is a file (not dir, not symlink)" \
  "test -f '$SANDBOX/.claude/dewey-analytics.log' && test ! -L '$SANDBOX/.claude/dewey-analytics.log'"

# When telemetry is disabled, analytics log should NOT be created
NOTEL_SANDBOX="$(mktemp -d)"
NOTEL_DEWEY="$NOTEL_SANDBOX/.claude/dewey"
TMPDIRS_TO_CLEAN+=("$NOTEL_SANDBOX")
mkdir -p "$NOTEL_DEWEY"
cp -R "$REPO_ROOT/." "$NOTEL_DEWEY/"
check "install.sh does NOT create analytics log when DEWEY_TELEMETRY=0" \
  "
DEWEY_TELEMETRY=0 HOME='$NOTEL_SANDBOX' DEWEY_DIR='$NOTEL_DEWEY' \
  DEWEY_REPO='file://$REPO_ROOT' DEWEY_REF=main DEWEY_USE_INPLACE=1 \
  bash '$REPO_ROOT/install.sh' >/dev/null 2>&1
test ! -f '$NOTEL_SANDBOX/.claude/dewey-analytics.log'
"

# Any JSONL written to the log by the first-run hook must be valid JSON
check "first-run hook appends valid JSON to analytics log" \
  "
HOME='$SANDBOX' bash '$SANDBOX/.claude/dewey-first-run.sh' >/dev/null 2>&1
if [ -s '$SANDBOX/.claude/dewey-analytics.log' ]; then
  python3 -c '
import json, sys
with open(\"$SANDBOX/.claude/dewey-analytics.log\") as f:
    for i, line in enumerate(f, 1):
        line = line.strip()
        if line:
            try:
                obj = json.loads(line)
                assert \"ts\" in obj, f\"line {i}: missing ts\"
                assert \"event\" in obj, f\"line {i}: missing event\"
            except json.JSONDecodeError as e:
                sys.exit(f\"line {i}: invalid JSON: {e}\")
'
fi
"

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

# ============================================================================
# LAYER 11: SURFACE COMPATIBILITY
# ============================================================================
section "Layer 11 — Surface compatibility"

VALID_SURFACES='claude-code cowork codex chat'

for plugin_dir in plugins/*/; do
  plugin_name=$(basename "$plugin_dir")
  manifest="$plugin_dir.claude-plugin/plugin.json"

  check "[$plugin_name] plugin.json declares 'surfaces' array" \
    "python3 -c '
import json, sys
p = json.load(open(\"$manifest\"))
s = p.get(\"surfaces\")
assert isinstance(s, list), \"surfaces must be a list\"
assert len(s) > 0, \"surfaces must be non-empty\"
for v in s: assert v in {\"claude-code\",\"cowork\",\"codex\",\"chat\"}, f\"invalid surface: {v}\"
'"

  # If plugin claims chat support, no SKILL.md inside may use Bash in allowed-tools.
  check "[$plugin_name] no chat-claimed skill uses Bash in allowed-tools" \
    "python3 -c '
import json, re, glob, os, sys
manifest = \"$manifest\"
plugin_dir = \"$plugin_dir\"
p = json.load(open(manifest))
surfaces = p.get(\"surfaces\", [\"claude-code\"])
if \"chat\" not in surfaces: sys.exit(0)
for skill_md in glob.glob(os.path.join(plugin_dir, \"skills\", \"*\", \"SKILL.md\")):
    text = open(skill_md).read()
    m = re.match(r\"^---\\n(.*?)\\n---\", text, re.DOTALL)
    if not m: continue
    fm = m.group(1)
    for line in fm.splitlines():
        if line.startswith(\"allowed-tools:\") and \"Bash\" in line:
            sys.exit(f\"{skill_md} declares Bash but plugin claims chat support\")
'"
done

# docs/surfaces.md exists
check "docs/surfaces.md exists" \
  "test -f '$REPO_ROOT/docs/surfaces.md'"

# Guide skill mentions surface awareness (so the runtime filtering instructions are present)
check "guide/SKILL.md documents surface detection" \
  "grep -q 'DEWEY_SURFACE' '$REPO_ROOT/guide/SKILL.md'"

# ============================================================================
# LAYER 12: EXTENSION TELEMETRY (helper, gates, schema, body-strip)
# ============================================================================
section "Layer 12 — Extension telemetry"

TELEMETRY_SRC="$REPO_ROOT/dewey-telemetry.sh"

check "dewey-telemetry.sh exists" \
  "test -f '$TELEMETRY_SRC'"

check "dewey-telemetry.sh has clean bash syntax" \
  "bash -n '$TELEMETRY_SRC'"

# Build a sandbox Dewey cache with one demo plugin + skill
TELEM_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$TELEM_SANDBOX")
TELEM_CACHE="$TELEM_SANDBOX/dewey"
TELEM_LOG="$TELEM_SANDBOX/log"
mkdir -p "$TELEM_CACHE/plugins/demo/.claude-plugin" "$TELEM_CACHE/plugins/demo/skills/foo"
printf '{"name":"demo"}\n' > "$TELEM_CACHE/plugins/demo/.claude-plugin/plugin.json"
printf -- "---\nname: foo\ndescription: x\n---\nbody\n" > "$TELEM_CACHE/plugins/demo/skills/foo/SKILL.md"

# Basic emit lands a JSONL line with required fields
check "emit appends a JSON line with ts, event, and provided fields" \
  "
DEWEY_DIR='$TELEM_CACHE' DEWEY_LOG='$TELEM_LOG' \
  bash '$TELEMETRY_SRC' emit event=test_event plugin=demo parent=foo additions='hello' tools_added='Bash(*),mcp:linear'
test -f '$TELEM_LOG'
python3 -c '
import json
line = open(\"$TELEM_LOG\").read().splitlines()[-1]
o = json.loads(line)
assert o[\"event\"] == \"test_event\"
assert o[\"plugin\"] == \"demo\"
assert o[\"parent\"] == \"foo\"
assert o[\"additions\"] == \"hello\"
assert o[\"tools_added\"] == [\"Bash(*)\", \"mcp:linear\"]
assert \"ts\" in o
'
"

# Global opt-out: DEWEY_TELEMETRY=0 suppresses
TELEM_LOG2="$TELEM_SANDBOX/log2"
check "DEWEY_TELEMETRY=0 suppresses emit (no log file created)" \
  "
DEWEY_TELEMETRY=0 DEWEY_DIR='$TELEM_CACHE' DEWEY_LOG='$TELEM_LOG2' \
  bash '$TELEMETRY_SRC' emit event=test plugin=demo
test ! -e '$TELEM_LOG2'
"

# Plugin-level opt-out: telemetry: false on plugin.json
TELEM_CACHE2="$TELEM_SANDBOX/dewey2"
TELEM_LOG3="$TELEM_SANDBOX/log3"
mkdir -p "$TELEM_CACHE2/plugins/demo/.claude-plugin" "$TELEM_CACHE2/plugins/demo/skills/foo"
printf '{"name":"demo","telemetry":false}\n' > "$TELEM_CACHE2/plugins/demo/.claude-plugin/plugin.json"
printf -- "---\nname: foo\n---\nbody\n" > "$TELEM_CACHE2/plugins/demo/skills/foo/SKILL.md"
check "plugin telemetry: false suppresses emit (no log file)" \
  "
DEWEY_DIR='$TELEM_CACHE2' DEWEY_LOG='$TELEM_LOG3' \
  bash '$TELEMETRY_SRC' emit event=test plugin=demo parent=foo
test ! -e '$TELEM_LOG3'
"

# Skill-level opt-out: telemetry: false in SKILL.md frontmatter (plugin allows)
TELEM_CACHE3="$TELEM_SANDBOX/dewey3"
TELEM_LOG4="$TELEM_SANDBOX/log4"
mkdir -p "$TELEM_CACHE3/plugins/demo/.claude-plugin" "$TELEM_CACHE3/plugins/demo/skills/foo"
printf '{"name":"demo"}\n' > "$TELEM_CACHE3/plugins/demo/.claude-plugin/plugin.json"
printf -- "---\nname: foo\ntelemetry: false\n---\nbody\n" > "$TELEM_CACHE3/plugins/demo/skills/foo/SKILL.md"
check "skill telemetry: false suppresses emit (no log file)" \
  "
DEWEY_DIR='$TELEM_CACHE3' DEWEY_LOG='$TELEM_LOG4' \
  bash '$TELEMETRY_SRC' emit event=test plugin=demo parent=foo
test ! -e '$TELEM_LOG4'
"

# strip-bodies removes additions/user_intent from extension_created by default
check "strip-bodies removes additions and user_intent by default" \
  "
out=\$(printf '%s\n' \
    '{\"event\":\"extension_created\",\"parent\":\"foo\",\"additions\":\"secret\",\"user_intent\":\"a\",\"tools_added\":[\"x\"]}' \
    '{\"event\":\"skill_install\",\"skill\":\"y\"}' \
  | bash '$TELEMETRY_SRC' strip-bodies)
echo \"\$out\" | python3 -c '
import json, sys
lines = sys.stdin.read().splitlines()
assert len(lines) == 2
ext = json.loads(lines[0])
assert ext[\"event\"] == \"extension_created\"
assert \"additions\" not in ext
assert \"user_intent\" not in ext
assert ext[\"tools_added\"] == [\"x\"]
inst = json.loads(lines[1])
assert inst[\"event\"] == \"skill_install\"
'
"

# strip-bodies with FORWARD_BODIES=1 preserves
check "DEWEY_TELEMETRY_FORWARD_BODIES=1 preserves additions and user_intent" \
  "
out=\$(echo '{\"event\":\"extension_created\",\"parent\":\"foo\",\"additions\":\"secret\",\"user_intent\":\"a\"}' \
  | DEWEY_TELEMETRY_FORWARD_BODIES=1 bash '$TELEMETRY_SRC' strip-bodies)
echo \"\$out\" | python3 -c '
import json, sys
o = json.loads(sys.stdin.read())
assert o[\"additions\"] == \"secret\"
assert o[\"user_intent\"] == \"a\"
'
"

# install.sh installs dewey-telemetry.sh
INSTALLED_TELEM="$SANDBOX/.claude/dewey-telemetry.sh"
check "install.sh installs dewey-telemetry.sh to \$HOME/.claude" \
  "test -f '$INSTALLED_TELEM' && test -x '$INSTALLED_TELEM'"

check "installed dewey-telemetry.sh has clean bash syntax" \
  "bash -n '$INSTALLED_TELEM'"

# Guide §3 calls the helper for extension_created
check "guide/SKILL.md §3 calls dewey-telemetry.sh emit for extension_created" \
  "grep -A1 -E '^## §3' '$REPO_ROOT/guide/SKILL.md' >/dev/null
grep -q 'dewey-telemetry.sh emit' '$REPO_ROOT/guide/SKILL.md'
grep -q 'event=extension_created' '$REPO_ROOT/guide/SKILL.md'"

# docs/extension-telemetry.md exists
check "docs/extension-telemetry.md exists" \
  "test -f '$REPO_ROOT/docs/extension-telemetry.md'"

check "docs/extension-telemetry.md describes 3 privacy layers" \
  "grep -q 'DEWEY_TELEMETRY=0' '$REPO_ROOT/docs/extension-telemetry.md' &&
   grep -q 'telemetry: false' '$REPO_ROOT/docs/extension-telemetry.md' &&
   grep -q 'DEWEY_TELEMETRY_FORWARD_BODIES' '$REPO_ROOT/docs/extension-telemetry.md'"

# ============================================================================
# LAYER 13: PROPOSE HELPER (--check, --prepare, propose --dry-run)
# ============================================================================
section "Layer 13 — Propose helper"

PROPOSE_SRC="$REPO_ROOT/dewey-propose.sh"

check "dewey-propose.sh exists" \
  "test -f '$PROPOSE_SRC'"

check "dewey-propose.sh has clean bash syntax" \
  "bash -n '$PROPOSE_SRC'"

check "dewey-propose.sh prints help with no args" \
  "bash '$PROPOSE_SRC' 2>&1 | grep -q 'dewey-propose'"

check "dewey-propose.sh rejects unknown subcommand" \
  "out=\$(bash '$PROPOSE_SRC' nope 2>&1); echo \"\$out\" | grep -q 'unknown command'; test \$(bash '$PROPOSE_SRC' nope 2>&1; echo \$?) -ne 0 || true"

# install.sh installs the helper (sandbox HOME is built earlier in Layer 6)
INSTALLED_PROPOSE="$SANDBOX/.claude/dewey-propose.sh"
check "install.sh installs dewey-propose.sh to \$HOME/.claude" \
  "test -f '$INSTALLED_PROPOSE' && test -x '$INSTALLED_PROPOSE'"

check "installed dewey-propose.sh has clean bash syntax" \
  "bash -n '$INSTALLED_PROPOSE'"

# Dry-run flow: build a fake working clone (looks like a Dewey repo) and
# verify the helper stages the file, runs lint, and exits 0 without pushing.
PROPOSE_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$PROPOSE_SANDBOX")
PROPOSE_AUTHOR_DIR="$PROPOSE_SANDBOX/dewey-author"
mkdir -p "$PROPOSE_AUTHOR_DIR"
git init --quiet "$PROPOSE_AUTHOR_DIR"
( cd "$PROPOSE_AUTHOR_DIR" && \
  git config user.email "test@test" && \
  git config user.name "test" && \
  mkdir -p plugins/demo/skills/foo plugins/demo/.claude-plugin tests && \
  printf '{"name":"demo"}\n' > plugins/demo/.claude-plugin/plugin.json && \
  printf -- "---\nname: foo\n---\n" > plugins/demo/skills/foo/SKILL.md && \
  cat > tests/run.sh <<'EOF'
#!/usr/bin/env bash
# Stub lint script — exits 0 always
echo "stub tests pass"
exit 0
EOF
  chmod +x tests/run.sh && \
  git add -A && \
  git commit --quiet -m "init" && \
  git branch -M main )

DRAFT="$PROPOSE_SANDBOX/draft.md"
BODY="$PROPOSE_SANDBOX/body.md"
printf -- "---\nname: bar\ndescription: test\n---\nbody\n" > "$DRAFT"
printf "Test PR body\n" > "$BODY"

check "propose --dry-run validates file, runs lint, exits 0 without pushing" \
  "
DEWEY_AUTHOR_DIR='$PROPOSE_AUTHOR_DIR' \
  bash '$PROPOSE_SRC' propose \
    --target-path 'plugins/demo/skills/bar/SKILL.md' \
    --content-file '$DRAFT' \
    --branch propose/test-bar \
    --title 'Add bar skill' \
    --body-file '$BODY' \
    --dry-run >/dev/null 2>&1
test \$? -eq 0
"

check "propose --dry-run leaves author checkout unchanged" \
  "
test \"\$(git -C '$PROPOSE_AUTHOR_DIR' branch --show-current)\" = 'main'
test ! -f '$PROPOSE_AUTHOR_DIR/plugins/demo/skills/bar/SKILL.md'
! git -C '$PROPOSE_AUTHOR_DIR' rev-parse --verify propose/test-bar >/dev/null 2>&1
"

git -C "$PROPOSE_AUTHOR_DIR" branch propose/existing main
EXISTING_BRANCH_SHA="$(git -C "$PROPOSE_AUTHOR_DIR" rev-parse propose/existing)"
check "propose --dry-run preserves an existing branch with the same name" \
  "
DEWEY_AUTHOR_DIR='$PROPOSE_AUTHOR_DIR' \
  bash '$PROPOSE_SRC' propose \
    --target-path 'plugins/demo/skills/bar/SKILL.md' \
    --content-file '$DRAFT' \
    --branch propose/existing \
    --title 'Add bar skill' \
    --body-file '$BODY' \
    --dry-run >/dev/null 2>&1
test \"\$(git -C '$PROPOSE_AUTHOR_DIR' rev-parse propose/existing)\" = '$EXISTING_BRANCH_SHA'
test \"\$(git -C '$PROPOSE_AUTHOR_DIR' branch --show-current)\" = 'main'
"

check "propose rejects absolute target-path" \
  "
out=\$(DEWEY_AUTHOR_DIR='$PROPOSE_AUTHOR_DIR' \
  bash '$PROPOSE_SRC' propose \
    --target-path '/etc/passwd' \
    --content-file '$DRAFT' \
    --branch x --title y --body-file '$BODY' --dry-run 2>&1)
echo \"\$out\" | grep -q 'must be a repo-relative path'
"

check "propose rejects target-path with .." \
  "
out=\$(DEWEY_AUTHOR_DIR='$PROPOSE_AUTHOR_DIR' \
  bash '$PROPOSE_SRC' propose \
    --target-path '../escape.md' \
    --content-file '$DRAFT' \
    --branch x --title y --body-file '$BODY' --dry-run 2>&1)
echo \"\$out\" | grep -q 'must be a repo-relative path'
"

check "propose rejects missing content file" \
  "
out=\$(DEWEY_AUTHOR_DIR='$PROPOSE_AUTHOR_DIR' \
  bash '$PROPOSE_SRC' propose \
    --target-path 'plugins/demo/skills/bar/SKILL.md' \
    --content-file '$PROPOSE_SANDBOX/nonexistent.md' \
    --branch x --title y --body-file '$BODY' --dry-run 2>&1)
echo \"\$out\" | grep -q 'content file not found'
"

# Helper requires --dry-run when working dir is missing in tests, since live
# mode would clone from the real GitHub repo.
check "propose --dry-run errors if working dir missing" \
  "
out=\$(DEWEY_AUTHOR_DIR='$PROPOSE_SANDBOX/missing' \
  bash '$PROPOSE_SRC' propose \
    --target-path 'plugins/demo/skills/bar/SKILL.md' \
    --content-file '$DRAFT' \
    --branch x --title y --body-file '$BODY' --dry-run 2>&1)
echo \"\$out\" | grep -q 'working dir does not exist'
"

# Guide §10 references the helper
check "guide/SKILL.md §10 calls dewey-propose.sh" \
  "grep -q 'dewey-propose.sh' '$REPO_ROOT/guide/SKILL.md' &&
   grep -q '## §10 Propose' '$REPO_ROOT/guide/SKILL.md'"

# docs exist
check "docs/proposing-changes.md exists" \
  "test -f '$REPO_ROOT/docs/proposing-changes.md'"

# ============================================================================
# LAYER 14: CANONICAL CONTEXT (schema, ID resolution, body alignment, size,
#                              surface compatibility, extension targets)
# ============================================================================
section "Layer 14 — Canonical context"

# Schema validation: every plugin.json's `context` array (if present) is well-formed
for plugin_dir in plugins/*/; do
  plugin_name=$(basename "$plugin_dir")
  manifest="$plugin_dir.claude-plugin/plugin.json"

  check "[$plugin_name] context entries are well-formed (if present)" \
    "python3 -c '
import json, os, re, sys
manifest = \"$manifest\"
plugin_dir = \"$plugin_dir\"
plugin_name = \"$plugin_name\"
p = json.load(open(manifest))
valid_surfaces = {\"claude-code\", \"cowork\", \"codex\", \"chat\"}
plugin_surfaces = p.get(\"surfaces\") or [\"claude-code\"]
ctx = p.get(\"context\")
if ctx is None: sys.exit(0)
assert isinstance(ctx, list), \"context must be a list\"
seen = set()
for entry in ctx:
    assert isinstance(entry, dict), \"context entry must be an object\"
    for required in (\"id\", \"path\", \"title\"):
        assert entry.get(required), f\"context entry missing required field: {required}\"
        assert isinstance(entry.get(required), str), f\"context field {required} must be a string\"
    cid = entry[\"id\"]
    assert cid.count(\"/\") == 1, f\"context id must be <plugin>/<bundle>: {cid}\"
    pseg, bseg = cid.split(\"/\", 1)
    assert pseg == plugin_name, f\"context id plugin segment {pseg!r} must match containing plugin {plugin_name!r}\"
    assert re.fullmatch(r\"[a-z0-9]+(-[a-z0-9]+)*\", bseg), f\"context id bundle segment must be kebab-case: {cid}\"
    assert cid not in seen, f\"duplicate context id: {cid}\"
    seen.add(cid)
    rel = entry[\"path\"]
    assert not rel.startswith(\"/\") and \"..\" not in rel.split(\"/\"), f\"context path must be relative without ..: {rel}\"
    assert rel.startswith(\"context/\"), f\"context path must live under context/: {rel}\"
    full = os.path.join(plugin_dir, rel)
    assert os.path.exists(full), f\"context path does not exist: {full}\"
    if \"description\" in entry:
        assert isinstance(entry[\"description\"], str), \"context description must be a string\"
    if \"allow-large-context\" in entry:
        assert isinstance(entry[\"allow-large-context\"], bool), \"allow-large-context must be boolean\"
    surfaces = entry.get(\"surfaces\")
    if surfaces is not None:
        assert isinstance(surfaces, list), \"context surfaces must be a list\"
        assert len(surfaces) > 0, \"context surfaces must be non-empty\"
        for s in surfaces:
            assert s in valid_surfaces, f\"invalid context surface: {s}\"
        assert set(surfaces).issubset(set(plugin_surfaces)), \"context surfaces must be a subset of plugin surfaces\"
'"

  check "[$plugin_name] context files respect size limits" \
    "python3 -c '
import json, os, sys
manifest = \"$manifest\"
plugin_dir = \"$plugin_dir\"
p = json.load(open(manifest))
ctx = p.get(\"context\") or []
WARN = 20 * 1024
FAIL = 100 * 1024
def files_under(root):
    if os.path.isfile(root): yield root; return
    for dp, _, fns in os.walk(root):
        for fn in fns:
            yield os.path.join(dp, fn)
for entry in ctx:
    full = os.path.join(plugin_dir, entry[\"path\"])
    allow_large = bool(entry.get(\"allow-large-context\"))
    for f in files_under(full):
        if not f.endswith(\".md\"):
            sys.exit(f\"{f} is inside a context bundle but is not markdown\")
        size = os.path.getsize(f)
        if size > FAIL and not allow_large:
            sys.exit(f\"{f} exceeds 100KB ({size} bytes); set allow-large-context: true on the entry to permit\")
'"
done

# Per-skill: requires-context resolves, appears in body, surface compat
for plugin_dir in plugins/*/; do
  plugin_name=$(basename "$plugin_dir")
  for skill_md in "$plugin_dir"skills/*/SKILL.md; do
    [ -f "$skill_md" ] || continue
    skill_rel="${skill_md#$REPO_ROOT/}"

    check "[$skill_rel] requires-context: IDs resolve, appear in body, surfaces compatible" \
      "python3 '$REPO_ROOT/tests/lib/check_requires_context.py' '$skill_md' '$plugin_dir' '$plugin_name'"
  done
done

# Demonstrator content exists end-to-end
check "competitive-intelligence positioning context file exists" \
  "test -f '$REPO_ROOT/plugins/competitive-intelligence/context/positioning/context.md'"

check "competitive-analysis declares requires-context: positioning" \
  "grep -q 'competitive-intelligence/positioning' '$REPO_ROOT/plugins/competitive-intelligence/skills/competitive-analysis/SKILL.md'"

# Negative-case fixtures: validator catches drift, missing IDs, and missing extension targets
LAYER14_FIXTURES="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$LAYER14_FIXTURES")
mkdir -p "$LAYER14_FIXTURES/plugins/demo/.claude-plugin" \
         "$LAYER14_FIXTURES/plugins/demo/skills/foo" \
         "$LAYER14_FIXTURES/plugins/demo/context/bar"
printf '%s\n' \
  '{"name":"demo","surfaces":["claude-code","cowork","codex","chat"],"context":[{"id":"demo/bar","path":"context/bar/bar.md","title":"Bar"}]}' \
  > "$LAYER14_FIXTURES/plugins/demo/.claude-plugin/plugin.json"
printf '%s\n' "stub bar context" > "$LAYER14_FIXTURES/plugins/demo/context/bar/bar.md"

# Case A: skill declares requires-context for an unknown ID
mkdir -p "$LAYER14_FIXTURES/plugins/demo/skills/skill_a"
cat > "$LAYER14_FIXTURES/plugins/demo/skills/skill_a/SKILL.md" <<'EOF'
---
name: skill_a
description: declares unknown
requires-context:
  - demo/nonexistent
---
First, load demo/nonexistent.

Body.
EOF

check "[fixture] validator rejects unknown requires-context id" \
  "
cd '$LAYER14_FIXTURES' && \
  ! python3 '$REPO_ROOT/tests/lib/check_requires_context.py' \
      'plugins/demo/skills/skill_a/SKILL.md' \
      'plugins/demo/' \
      'demo' >/dev/null 2>&1
"

# Case B: skill declares requires-context but body never references the id
mkdir -p "$LAYER14_FIXTURES/plugins/demo/skills/skill_b"
cat > "$LAYER14_FIXTURES/plugins/demo/skills/skill_b/SKILL.md" <<'EOF'
---
name: skill_b
description: drift case
requires-context:
  - demo/bar
---
This body never mentions the context.
EOF

check "[fixture] validator rejects frontmatter/body drift" \
  "
cd '$LAYER14_FIXTURES' && \
  ! python3 '$REPO_ROOT/tests/lib/check_requires_context.py' \
      'plugins/demo/skills/skill_b/SKILL.md' \
      'plugins/demo/' \
      'demo' >/dev/null 2>&1
"

# Case C: context extension targets an unknown ID
mkdir -p "$LAYER14_FIXTURES/plugins/demo/skills/skill_c"
cat > "$LAYER14_FIXTURES/plugins/demo/skills/skill_c/SKILL.md" <<'EOF'
---
name: skill_c
description: bad extension target
extends-context: demo/missing
---
This extends a missing context bundle.
EOF

check "[fixture] validator rejects unknown extends-context target" \
  "
cd '$LAYER14_FIXTURES' && \
  ! python3 '$REPO_ROOT/tests/lib/check_requires_context.py' \
      'plugins/demo/skills/skill_c/SKILL.md' \
      'plugins/demo/' \
      'demo' >/dev/null 2>&1
"

# Naming convention: every in-tree context entry's primary path ends in context.md
for plugin_dir in plugins/*/; do
  plugin_name=$(basename "$plugin_dir")

  check "[$plugin_name] context entries use the context.md primary-file convention" \
    "python3 '$REPO_ROOT/tests/lib/check_context_naming.py' '$plugin_dir'"
done

# Guide §11 Load: section exists and references the load mechanic
check "guide/SKILL.md §11 Load is present and documents the load flow" \
  "grep -q '## §11 Load' '$REPO_ROOT/guide/SKILL.md' &&
   grep -q '/dewey load' '$REPO_ROOT/guide/SKILL.md' &&
   grep -q 'context.md' '$REPO_ROOT/guide/SKILL.md'"

check "guide argument-hint includes load" \
  "grep -q 'load' '$REPO_ROOT/guide/SKILL.md' &&
   head -20 '$REPO_ROOT/guide/SKILL.md' | grep -q 'argument-hint.*load'"

# ============================================================================
# RESULTS
# ============================================================================
TOTAL=$((PASSED + FAILED))
printf "\n%s\n" "$(bold "Results:")"
printf "  Total:  %d\n" "$TOTAL"
printf "  %s: %d\n" "$(green Passed)" "$PASSED"
printf "  %s: %d\n" "$(red Failed)" "$FAILED"

if [ "$FAILED" -gt 0 ]; then
  printf "\n%s\n" "$(red "Failed tests:")"
  for n in "${FAILED_NAMES[@]}"; do
    printf "  - %s\n" "$n"
  done
  exit 1
fi

printf "\n%s\n" "$(green "All tests passed.")"
exit 0
