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
