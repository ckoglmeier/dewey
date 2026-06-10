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
