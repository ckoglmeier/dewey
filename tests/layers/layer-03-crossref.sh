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
# For any plugin whose "source" is an object (not a "./" string), validate
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
