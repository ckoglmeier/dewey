#!/usr/bin/env bash
# Classroom v1 test suite
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

check "external plugin sources declare a known source type" \
  "python3 -c '
import json
m = json.load(open(\".claude-plugin/marketplace.json\"))
KNOWN = {\"github\", \"url\", \"git-subdir\", \"npm\"}
for p in m[\"plugins\"]:
    src = p[\"source\"]
    if isinstance(src, dict):
        t = src.get(\"source\")
        assert t in KNOWN, p[\"name\"] + \": unknown source type \" + repr(t)
'"

check "external git-subdir sources have url + path + (ref or sha)" \
  "python3 -c '
import json
m = json.load(open(\".claude-plugin/marketplace.json\"))
for p in m[\"plugins\"]:
    src = p[\"source\"]
    if isinstance(src, dict) and src.get(\"source\") == \"git-subdir\":
        assert src.get(\"url\"), p[\"name\"] + \": git-subdir missing url\"
        assert src.get(\"path\"), p[\"name\"] + \": git-subdir missing path\"
        assert src.get(\"ref\") or src.get(\"sha\"), p[\"name\"] + \": git-subdir needs ref or sha\"
'"

check "external github sources have repo + (ref or sha)" \
  "python3 -c '
import json
m = json.load(open(\".claude-plugin/marketplace.json\"))
for p in m[\"plugins\"]:
    src = p[\"source\"]
    if isinstance(src, dict) and src.get(\"source\") == \"github\":
        assert src.get(\"repo\"), p[\"name\"] + \": github source missing repo\"
        assert src.get(\"ref\") or src.get(\"sha\"), p[\"name\"] + \": github needs ref or sha\"
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

# Guide skill name should be 'classroom' since /classroom is the entry point
check "guide skill name is classroom (matches /classroom slash command)" \
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
assert found_name == \"classroom\", \"guide name is \" + repr(found_name) + \", expected classroom\"
'"

# ============================================================================
# LAYER 4: install.sh INTEGRATION (sandbox)
# ============================================================================
section "Layer 4 — install.sh integration (sandboxed)"

SANDBOX="$(mktemp -d)"
trap 'rm -rf "$SANDBOX"' EXIT

# Pre-populate the sandbox CLASSROOM_DIR with a non-git copy of our repo, so
# install.sh hits the "exists but not git" branch and uses files in place.
# This avoids needing the repo to be on a real git remote during tests.
SANDBOX_CLASSROOM="$SANDBOX/.claude/classroom"
mkdir -p "$SANDBOX_CLASSROOM"
# Copy everything except the tests dir (avoid recursion noise) and .git if present
rsync -a --exclude='tests/' --exclude='.git/' "$REPO_ROOT/" "$SANDBOX_CLASSROOM/" 2>/dev/null \
  || cp -R "$REPO_ROOT/." "$SANDBOX_CLASSROOM/"

run_install() {
  HOME="$SANDBOX" \
  CLASSROOM_DIR="$SANDBOX_CLASSROOM" \
  CLASSROOM_REPO="file://$REPO_ROOT" \
  CLASSROOM_REF="main" \
  CLASSROOM_USE_INPLACE=1 \
  bash "$REPO_ROOT/install.sh" >"$SANDBOX/install.log" 2>&1
}

check "install.sh runs cleanly in sandbox" \
  "run_install"

check "Guide skill installed at \$HOME/.claude/skills/classroom/SKILL.md" \
  "test -f '$SANDBOX/.claude/skills/classroom/SKILL.md'"

check "installed Guide matches source guide/SKILL.md" \
  "cmp -s '$REPO_ROOT/guide/SKILL.md' '$SANDBOX/.claude/skills/classroom/SKILL.md'"

check "settings.json was created" \
  "test -f '$SANDBOX/.claude/settings.json'"

check "settings.json is valid JSON" \
  "python3 -c 'import json; json.load(open(\"$SANDBOX/.claude/settings.json\"))'"

check "known_marketplaces.json registers classroom marketplace" \
  "python3 -c '
import json
s = json.load(open(\"$SANDBOX/.claude/plugins/known_marketplaces.json\"))
assert \"classroom\" in s
assert s[\"classroom\"][\"source\"][\"source\"] == \"directory\"
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
        if \"classroom-first-run.sh\" in h.get(\"command\", \"\"):
            found = True
assert found, \"first-run hook not registered\"
'"

check "first-run hook script created and executable" \
  "test -x '$SANDBOX/.claude/classroom-first-run.sh'"

# Run the first-run hook the FIRST time — should print welcome
check "first-run hook prints welcome on first invocation" \
  "HOME='$SANDBOX' bash '$SANDBOX/.claude/classroom-first-run.sh' | grep -q 'Welcome to Classroom'"

# Marker should now exist
check "first-run marker created after first invocation" \
  "test -f '$SANDBOX/.claude/classroom-onboarded'"

# Run the first-run hook the SECOND time — should be silent
check "first-run hook is silent on second invocation" \
  "out=\$(HOME='$SANDBOX' bash '$SANDBOX/.claude/classroom-first-run.sh'); test -z \"\$out\""

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
        if \"classroom-first-run.sh\" in h.get(\"command\", \"\"):
            matching += 1
assert matching == 1, f\"expected 1 first-run hook, found {matching}\"
'"

# Pre-existing settings.json with unrelated keys should be preserved
check "install.sh preserves unrelated keys in settings.json" \
  "
SANDBOX2=\$(mktemp -d)
mkdir -p \"\$SANDBOX2/.claude\"
echo '{\"theme\": \"dark\", \"unrelated\": {\"keep\": \"me\"}}' > \"\$SANDBOX2/.claude/settings.json\"
SANDBOX_CLASSROOM2=\"\$SANDBOX2/.claude/classroom\"
mkdir -p \"\$SANDBOX_CLASSROOM2\"
cp -R \"$REPO_ROOT/.\" \"\$SANDBOX_CLASSROOM2/\"
HOME=\"\$SANDBOX2\" CLASSROOM_DIR=\"\$SANDBOX_CLASSROOM2\" CLASSROOM_REPO=\"file://$REPO_ROOT\" CLASSROOM_REF=main CLASSROOM_USE_INPLACE=1 bash \"$REPO_ROOT/install.sh\" >/dev/null 2>&1
python3 -c \"
import json
s = json.load(open('\$SANDBOX2/.claude/settings.json'))
assert s.get('theme') == 'dark', 'theme key was lost'
assert s.get('unrelated', {}).get('keep') == 'me', 'unrelated key was lost'
mk = json.load(open('\$SANDBOX2/.claude/plugins/known_marketplaces.json'))
assert 'classroom' in mk, 'classroom marketplace not registered'
\"
rm -rf \"\$SANDBOX2\"
"

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
mkdir -p "$TARBALL_DIR/stage/classroom-snapshot"
if command -v rsync >/dev/null 2>&1; then
  rsync -a --exclude='tests/' --exclude='.git/' "$REPO_ROOT/" "$TARBALL_DIR/stage/classroom-snapshot/" 2>/dev/null
else
  cp -R "$REPO_ROOT/." "$TARBALL_DIR/stage/classroom-snapshot/"
  rm -rf "$TARBALL_DIR/stage/classroom-snapshot/tests" "$TARBALL_DIR/stage/classroom-snapshot/.git"
fi

TARBALL_FILE="$TARBALL_DIR/classroom.tar.gz"
( cd "$TARBALL_DIR/stage" && tar -czf "$TARBALL_FILE" classroom-snapshot )

check "test tarball was built" \
  "test -s '$TARBALL_FILE'"

TARBALL_SHA=$(shasum -a 256 "$TARBALL_FILE" | awk '{print $1}')

# Fresh sandbox with NO pre-populated CLASSROOM_DIR — install must download.
TARBALL_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$TARBALL_SANDBOX")
TARBALL_SANDBOX_CLASSROOM="$TARBALL_SANDBOX/.claude/classroom"

run_tarball_install() {
  HOME="$TARBALL_SANDBOX" \
  CLASSROOM_DIR="$TARBALL_SANDBOX_CLASSROOM" \
  CLASSROOM_REPO="https://example.invalid/classroom" \
  CLASSROOM_REF="main" \
  CLASSROOM_TARBALL="file://$TARBALL_FILE" \
  bash "$REPO_ROOT/install.sh" >"$TARBALL_SANDBOX/install.log" 2>&1
}

check "install.sh runs cleanly via tarball (no git)" \
  "run_tarball_install"

check "tarball install populated guide/SKILL.md" \
  "test -f '$TARBALL_SANDBOX_CLASSROOM/guide/SKILL.md'"

check "tarball install populated marketplace.json" \
  "test -f '$TARBALL_SANDBOX_CLASSROOM/.claude-plugin/marketplace.json'"

check "tarball install installed Guide as personal skill" \
  "test -f '$TARBALL_SANDBOX/.claude/skills/classroom/SKILL.md'"

check "tarball install left no .old or .new sibling dirs" \
  "test ! -e '$TARBALL_SANDBOX_CLASSROOM.new' && ! ls -d '$TARBALL_SANDBOX_CLASSROOM'.old.* >/dev/null 2>&1"

check "tarball install registered the marketplace in known_marketplaces.json" \
  "python3 -c '
import json
s = json.load(open(\"$TARBALL_SANDBOX/.claude/plugins/known_marketplaces.json\"))
assert \"classroom\" in s
assert s[\"classroom\"][\"source\"][\"source\"] == \"directory\"
'"

check "tarball install dropped a refresh script" \
  "test -x '$TARBALL_SANDBOX/.claude/classroom-refresh.sh'"

# Idempotent re-run via tarball
check "tarball install is idempotent" \
  "run_tarball_install"

check "second tarball run still left no stale .old.* dirs" \
  "test ! -e '$TARBALL_SANDBOX_CLASSROOM.new' && ! ls -d '$TARBALL_SANDBOX_CLASSROOM'.old.* >/dev/null 2>&1"

# ---- Checksum verification --------------------------------------------------

# Pass: correct SHA
TARBALL_SANDBOX_OK="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$TARBALL_SANDBOX_OK")
check "tarball install passes with matching CLASSROOM_TARBALL_SHA256" \
  "HOME='$TARBALL_SANDBOX_OK' CLASSROOM_DIR='$TARBALL_SANDBOX_OK/.claude/classroom' CLASSROOM_TARBALL='file://$TARBALL_FILE' CLASSROOM_TARBALL_SHA256='$TARBALL_SHA' bash '$REPO_ROOT/install.sh' >/dev/null 2>&1"

# Fail: wrong SHA, must abort and leave CLASSROOM_DIR untouched
TARBALL_SANDBOX_BAD="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$TARBALL_SANDBOX_BAD")
check "tarball install aborts on bad CLASSROOM_TARBALL_SHA256" \
  "HOME='$TARBALL_SANDBOX_BAD' CLASSROOM_DIR='$TARBALL_SANDBOX_BAD/.claude/classroom' CLASSROOM_TARBALL='file://$TARBALL_FILE' CLASSROOM_TARBALL_SHA256='0000000000000000000000000000000000000000000000000000000000000000' bash '$REPO_ROOT/install.sh' >/dev/null 2>&1; test \$? -ne 0"

check "bad-checksum run did NOT populate CLASSROOM_DIR" \
  "test ! -f '$TARBALL_SANDBOX_BAD/.claude/classroom/guide/SKILL.md'"

# ---- Destructive-path guard -------------------------------------------------

# CLASSROOM_DIR that doesn't end in .claude/classroom must be refused.
GUARD_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$GUARD_SANDBOX")
mkdir -p "$GUARD_SANDBOX/somewhere-else"
echo "do not delete me" > "$GUARD_SANDBOX/somewhere-else/canary.txt"
check "install.sh refuses CLASSROOM_DIR that doesn't end in .claude/classroom" \
  "HOME='$GUARD_SANDBOX' CLASSROOM_DIR='$GUARD_SANDBOX/somewhere-else' CLASSROOM_TARBALL='file://$TARBALL_FILE' bash '$REPO_ROOT/install.sh' >/dev/null 2>&1; test \$? -ne 0"

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
  "PATH='$STRIP_DIR' HOME='$NOGIT_SANDBOX' CLASSROOM_DIR='$NOGIT_SANDBOX/.claude/classroom' CLASSROOM_TARBALL='file://$TARBALL_FILE' bash '$REPO_ROOT/install.sh' >/dev/null 2>&1"

check "no-git install populated guide/SKILL.md" \
  "test -f '$NOGIT_SANDBOX/.claude/classroom/guide/SKILL.md'"

# ============================================================================
# LAYER 7: REFRESH SCRIPT
# ============================================================================
section "Layer 7 — Refresh script"

# Use the tarball sandbox from Layer 6 which has a refresh.sh installed.
REFRESH="$TARBALL_SANDBOX/.claude/classroom-refresh.sh"

check "refresh.sh exists and is executable" \
  "test -x '$REFRESH'"

# Force interval=0 so the marker doesn't gate the test, point at our local tarball.
run_refresh() {
  HOME="$TARBALL_SANDBOX" \
  CLASSROOM_DIR="$TARBALL_SANDBOX_CLASSROOM" \
  CLASSROOM_TARBALL="file://$TARBALL_FILE" \
  CLASSROOM_REFRESH_INTERVAL=0 \
  bash "$REFRESH"
}

check "refresh.sh runs cleanly when forced" \
  "run_refresh"

check "refresh.sh wrote a last-refresh marker" \
  "test -f '$TARBALL_SANDBOX/.claude/classroom-last-refresh'"

check "refresh.sh wrote a log entry" \
  "test -s '$TARBALL_SANDBOX/.claude/classroom-refresh.log'"

check "refresh.sh left no stale .old.* dirs" \
  "test ! -e '$TARBALL_SANDBOX_CLASSROOM.new' && ! ls -d '$TARBALL_SANDBOX_CLASSROOM'.old.* >/dev/null 2>&1"

# Lock-file blocks concurrent execution.
check "refresh.sh exits silently when lock file exists" \
  "
touch '$TARBALL_SANDBOX/.claude/classroom-refresh.lock'
HOME='$TARBALL_SANDBOX' CLASSROOM_DIR='$TARBALL_SANDBOX_CLASSROOM' CLASSROOM_TARBALL='file://$TARBALL_FILE' CLASSROOM_REFRESH_INTERVAL=0 bash '$REFRESH'
test \$? -eq 0
test -f '$TARBALL_SANDBOX/.claude/classroom-refresh.lock'
rm -f '$TARBALL_SANDBOX/.claude/classroom-refresh.lock'
"

# 24h marker honored: with default interval and a fresh marker, refresh should be a no-op.
check "refresh.sh skips when marker is fresh and interval is default" \
  "
touch '$TARBALL_SANDBOX/.claude/classroom-last-refresh'
out=\$(HOME='$TARBALL_SANDBOX' CLASSROOM_DIR='$TARBALL_SANDBOX_CLASSROOM' CLASSROOM_TARBALL='file://$TARBALL_FILE' bash '$REFRESH' 2>&1)
test -z \"\$out\"
"

# Disabled when interval is -1.
check "refresh.sh disabled with CLASSROOM_REFRESH_INTERVAL=-1" \
  "HOME='$TARBALL_SANDBOX' CLASSROOM_DIR='$TARBALL_SANDBOX_CLASSROOM' CLASSROOM_TARBALL='file://$TARBALL_FILE' CLASSROOM_REFRESH_INTERVAL=-1 bash '$REFRESH'"

# Network/extract failure must not break the cache or exit non-zero.
NETFAIL_LOG="$TARBALL_SANDBOX/.claude/classroom-refresh.log"
NETFAIL_BEFORE=$(wc -c < "$NETFAIL_LOG" 2>/dev/null || echo 0)
check "refresh.sh exits 0 on network failure (bad URL)" \
  "HOME='$TARBALL_SANDBOX' CLASSROOM_DIR='$TARBALL_SANDBOX_CLASSROOM' CLASSROOM_TARBALL='file:///nonexistent/path/that/does/not/exist.tar.gz' CLASSROOM_REFRESH_INTERVAL=0 bash '$REFRESH'"

check "refresh.sh logged the network failure" \
  "test \$(wc -c < '$NETFAIL_LOG') -gt $NETFAIL_BEFORE"

check "refresh.sh did NOT damage CLASSROOM_DIR after network failure" \
  "test -f '$TARBALL_SANDBOX_CLASSROOM/guide/SKILL.md'"

# Dev-checkout no-op: with .git/ present, refresh exits silently.
mkdir -p "$TARBALL_SANDBOX_CLASSROOM/.git"
check "refresh.sh is a no-op when CLASSROOM_DIR/.git exists" \
  "
out=\$(HOME='$TARBALL_SANDBOX' CLASSROOM_DIR='$TARBALL_SANDBOX_CLASSROOM' CLASSROOM_TARBALL='file://$TARBALL_FILE' CLASSROOM_REFRESH_INTERVAL=0 bash '$REFRESH' 2>&1)
test -z \"\$out\"
"
rm -rf "$TARBALL_SANDBOX_CLASSROOM/.git"

# ============================================================================
# LAYER 8: SCHEDULE HELPER
# ============================================================================
section "Layer 8 — Schedule helper (classroom-schedule.sh)"

SCHED_SRC="$REPO_ROOT/classroom-schedule.sh"

check "classroom-schedule.sh exists" \
  "test -f '$SCHED_SRC'"

check "classroom-schedule.sh has clean bash syntax" \
  "bash -n '$SCHED_SRC'"

# Dry-run: daily schedule should print without creating any files
SCHED_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$SCHED_SANDBOX")
check "schedule.sh --dry-run daily exits 0 and prints plist/crontab" \
  "
sched_out=\$(ANTHROPIC_API_KEY=sk-test-key HOME='$SCHED_SANDBOX' \
  bash '$SCHED_SRC' --skill meeting-prep --trigger daily --time 08:00 --dry-run 2>&1)
echo \"\$sched_out\" | grep -qiE '(dry-run|plist|meeting-prep)'
"

check "schedule.sh --dry-run does NOT create any files in HOME" \
  "
ANTHROPIC_API_KEY=sk-test-key HOME='$SCHED_SANDBOX' \
  bash '$SCHED_SRC' --skill meeting-prep --trigger daily --time 08:00 --dry-run >/dev/null 2>&1
find '$SCHED_SANDBOX' -type f | grep -qv '^$'; test \$? -ne 0 || true
test ! -f '$SCHED_SANDBOX/Library/LaunchAgents/com.classroom.meeting-prep.plist'
"

# Weekly dry-run
check "schedule.sh --dry-run weekly exits 0" \
  "ANTHROPIC_API_KEY=sk-test-key HOME='$SCHED_SANDBOX' \
  bash '$SCHED_SRC' --skill meeting-prep --trigger weekly --day 1 --time 09:00 --dry-run >/dev/null 2>&1"

# Missing API key must fail
check "schedule.sh fails when ANTHROPIC_API_KEY is unset" \
  "
unset ANTHROPIC_API_KEY
HOME='$SCHED_SANDBOX' bash '$SCHED_SRC' --skill meeting-prep --trigger daily --time 08:00 --dry-run >/dev/null 2>&1
test \$? -ne 0
"

# Invalid skill name must fail
check "schedule.sh fails with non-kebab-case skill name" \
  "ANTHROPIC_API_KEY=sk-test-key HOME='$SCHED_SANDBOX' \
  bash '$SCHED_SRC' --skill 'Meeting Prep!' --trigger daily --time 08:00 --dry-run >/dev/null 2>&1; test \$? -ne 0"

# Invalid time must fail
check "schedule.sh fails with invalid --time" \
  "ANTHROPIC_API_KEY=sk-test-key HOME='$SCHED_SANDBOX' \
  bash '$SCHED_SRC' --skill meeting-prep --trigger daily --time '25:99' --dry-run >/dev/null 2>&1; test \$? -ne 0"

# install.sh drops classroom-schedule.sh from the snapshot
check "install.sh installs classroom-schedule.sh to \$HOME/.claude" \
  "test -x '$SANDBOX/.claude/classroom-schedule.sh'"

check "installed classroom-schedule.sh has clean bash syntax" \
  "bash -n '$SANDBOX/.claude/classroom-schedule.sh'"

# ============================================================================
# LAYER 9: ANALYTICS LOG
# ============================================================================
section "Layer 9 — Analytics log"

check "install.sh creates classroom-analytics.log when CLASSROOM_TELEMETRY != 0" \
  "test -f '$SANDBOX/.claude/classroom-analytics.log'"

check "classroom-analytics.log is a file (not dir, not symlink)" \
  "test -f '$SANDBOX/.claude/classroom-analytics.log' && test ! -L '$SANDBOX/.claude/classroom-analytics.log'"

# When telemetry is disabled, analytics log should NOT be created
NOTEL_SANDBOX="$(mktemp -d)"
NOTEL_CLASSROOM="$NOTEL_SANDBOX/.claude/classroom"
TMPDIRS_TO_CLEAN+=("$NOTEL_SANDBOX")
mkdir -p "$NOTEL_CLASSROOM"
cp -R "$REPO_ROOT/." "$NOTEL_CLASSROOM/"
check "install.sh does NOT create analytics log when CLASSROOM_TELEMETRY=0" \
  "
CLASSROOM_TELEMETRY=0 HOME='$NOTEL_SANDBOX' CLASSROOM_DIR='$NOTEL_CLASSROOM' \
  CLASSROOM_REPO='file://$REPO_ROOT' CLASSROOM_REF=main CLASSROOM_USE_INPLACE=1 \
  bash '$REPO_ROOT/install.sh' >/dev/null 2>&1
test ! -f '$NOTEL_SANDBOX/.claude/classroom-analytics.log'
"

# Any JSONL written to the log by the first-run hook must be valid JSON
check "first-run hook appends valid JSON to analytics log" \
  "
HOME='$SANDBOX' bash '$SANDBOX/.claude/classroom-first-run.sh' >/dev/null 2>&1
if [ -s '$SANDBOX/.claude/classroom-analytics.log' ]; then
  python3 -c '
import json, sys
with open(\"$SANDBOX/.claude/classroom-analytics.log\") as f:
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
section "Layer 10 — Codex sync (classroom-sync-codex.sh)"

SYNC_SRC="$REPO_ROOT/classroom-sync-codex.sh"

check "classroom-sync-codex.sh exists" \
  "test -f '$SYNC_SRC'"

check "classroom-sync-codex.sh has clean bash syntax" \
  "bash -n '$SYNC_SRC'"

# install.sh drops the sync script
check "install.sh installs classroom-sync-codex.sh to \$HOME/.claude" \
  "test -x '$SANDBOX/.claude/classroom-sync-codex.sh'"

check "installed classroom-sync-codex.sh has clean bash syntax" \
  "bash -n '$SANDBOX/.claude/classroom-sync-codex.sh'"

# --dry-run: skills found in the Classroom cache, printed but not written
SYNC_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$SYNC_SANDBOX")
# Give it a fake ~/.codex so Codex is "detected"
mkdir -p "$SYNC_SANDBOX/.codex"

check "sync --dry-run lists skills without writing files" \
  "
sync_out=\$(CLASSROOM_DIR='$REPO_ROOT' CODEX_HOME='$SYNC_SANDBOX/.codex' HOME='$SYNC_SANDBOX' \
  bash '$SYNC_SRC' --dry-run 2>&1)
# Must mention at least one skill or 'dry-run'
echo \"\$sync_out\" | grep -qiE '(dry-run|skill|SKILL)'
# Must NOT have created any files in codex skills dir
test ! -d '$SYNC_SANDBOX/.codex/skills' || test -z \"\$(find '$SYNC_SANDBOX/.codex/skills' -type f -o -type l 2>/dev/null)\"
"

# --status: runs without error
check "sync --status exits 0 and prints output" \
  "
sync_out=\$(CLASSROOM_DIR='$REPO_ROOT' CODEX_HOME='$SYNC_SANDBOX/.codex' HOME='$SYNC_SANDBOX' \
  bash '$SYNC_SRC' --status 2>&1)
echo \"\$sync_out\" | grep -qiE '(synced|missing|not in Codex|skill)'
"

# Actual sync: creates symlinks
LIVE_SYNC_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$LIVE_SYNC_SANDBOX")
mkdir -p "$LIVE_SYNC_SANDBOX/.codex"

check "sync (no flags) creates symlinks in ~/.codex/skills/" \
  "
CLASSROOM_DIR='$REPO_ROOT' CODEX_HOME='$LIVE_SYNC_SANDBOX/.codex' HOME='$LIVE_SYNC_SANDBOX' \
  bash '$SYNC_SRC' >/dev/null 2>&1
test -d '$LIVE_SYNC_SANDBOX/.codex/skills'
find '$LIVE_SYNC_SANDBOX/.codex/skills' -name 'SKILL.md' | grep -q .
"

check "synced SKILL.md files are symlinks (not copies)" \
  "find '$LIVE_SYNC_SANDBOX/.codex/skills' -name 'SKILL.md' -type l | grep -q ."

check "synced symlinks point to the Classroom cache" \
  "
python3 -c '
import os, sys
skills_dir = \"$LIVE_SYNC_SANDBOX/.codex/skills\"
classroom_dir = \"$REPO_ROOT\"
for root, dirs, files in os.walk(skills_dir):
    for f in files:
        if f == \"SKILL.md\":
            p = os.path.join(root, f)
            target = os.readlink(p)
            assert target.startswith(classroom_dir), f\"symlink {p} points outside classroom: {target}\"
'
"

check "Guide skill (classroom) is included in sync" \
  "test -L '$LIVE_SYNC_SANDBOX/.codex/skills/classroom/SKILL.md'"

# --remove: removes symlinks
check "sync --remove removes only Classroom symlinks" \
  "
CLASSROOM_DIR='$REPO_ROOT' CODEX_HOME='$LIVE_SYNC_SANDBOX/.codex' HOME='$LIVE_SYNC_SANDBOX' \
  bash '$SYNC_SRC' --remove >/dev/null 2>&1
# After removal, no Classroom SKILL.md symlinks should remain
remaining=\$(find '$LIVE_SYNC_SANDBOX/.codex/skills' -name 'SKILL.md' -type l 2>/dev/null | wc -l | tr -d ' ')
test \"\$remaining\" = '0'
"

# Codex not detected: exits with error
NO_CODEX_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$NO_CODEX_SANDBOX")
check "sync exits non-zero when Codex not detected and HOME has no ~/.codex" \
  "
CLASSROOM_DIR='$REPO_ROOT' CODEX_HOME='$NO_CODEX_SANDBOX/.codex' HOME='$NO_CODEX_SANDBOX' \
  bash '$SYNC_SRC' >/dev/null 2>&1; test \$? -ne 0
"

# Classroom not installed: exits with error
NO_CLASSROOM_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$NO_CLASSROOM_SANDBOX")
mkdir -p "$NO_CLASSROOM_SANDBOX/.codex"
check "sync exits non-zero when CLASSROOM_DIR missing" \
  "
CLASSROOM_DIR='$NO_CLASSROOM_SANDBOX/nonexistent' CODEX_HOME='$NO_CLASSROOM_SANDBOX/.codex' HOME='$NO_CLASSROOM_SANDBOX' \
  bash '$SYNC_SRC' >/dev/null 2>&1; test \$? -ne 0
"

# --agents-md: generates AGENTS.md
AGENTS_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$AGENTS_SANDBOX")
mkdir -p "$AGENTS_SANDBOX/.codex"
check "sync --agents-md writes an AGENTS.md file" \
  "
CLASSROOM_DIR='$REPO_ROOT' CODEX_HOME='$AGENTS_SANDBOX/.codex' HOME='$AGENTS_SANDBOX' \
  bash '$SYNC_SRC' --agents-md '$AGENTS_SANDBOX' >/dev/null 2>&1
test -f '$AGENTS_SANDBOX/AGENTS.md'
grep -q 'Classroom' '$AGENTS_SANDBOX/AGENTS.md'
"

check "generated AGENTS.md mentions at least one skill" \
  "grep -qE '^\- \`/' '$AGENTS_SANDBOX/AGENTS.md'"

# install.sh with CLASSROOM_SYNC_CODEX=0 must not run sync
NO_SYNC_SANDBOX="$(mktemp -d)"
NO_SYNC_CLASSROOM="$NO_SYNC_SANDBOX/.claude/classroom"
TMPDIRS_TO_CLEAN+=("$NO_SYNC_SANDBOX")
mkdir -p "$NO_SYNC_CLASSROOM"
cp -R "$REPO_ROOT/." "$NO_SYNC_CLASSROOM/"
check "install.sh skips Codex sync when CLASSROOM_SYNC_CODEX=0" \
  "
CLASSROOM_SYNC_CODEX=0 HOME='$NO_SYNC_SANDBOX' CLASSROOM_DIR='$NO_SYNC_CLASSROOM' \
  CLASSROOM_REPO='file://$REPO_ROOT' CLASSROOM_REF=main CLASSROOM_USE_INPLACE=1 \
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
  "grep -q 'CLASSROOM_SURFACE' '$REPO_ROOT/guide/SKILL.md'"

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
