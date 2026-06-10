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
