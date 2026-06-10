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
