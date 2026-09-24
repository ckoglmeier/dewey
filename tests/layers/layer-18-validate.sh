# ============================================================================
# LAYER 18: CLAUDE CODE MANIFEST VALIDATION (claude plugin validate --strict)
# ============================================================================
# Runs Anthropic's own validator against the marketplace and every plugin.
# --strict turns "unrecognized field" warnings into failures, which is how we
# keep Dewey-specific keys under the official free-form `metadata` object.
# Skipped when no `claude` CLI with --strict support is on PATH (the flag
# arrived in Claude Code 2.1.2xx; CI runners and older installs skip cleanly).
section "Layer 18 — claude plugin validate --strict"

if command -v claude >/dev/null 2>&1 && claude plugin validate --help 2>/dev/null | grep -q -- '--strict'; then
  check "marketplace manifest passes claude plugin validate --strict" \
    "env -u CLAUDECODE claude plugin validate --strict '$REPO_ROOT' >/dev/null 2>&1"

  for plugin_dir in plugins/*/; do
    plugin_name=$(basename "$plugin_dir")
    check "[$plugin_name] plugin.json passes claude plugin validate --strict" \
      "env -u CLAUDECODE claude plugin validate --strict '$REPO_ROOT/$plugin_dir' >/dev/null 2>&1"
  done
else
  printf "  %s Layer 18 skipped: no 'claude' CLI with 'plugin validate --strict' on PATH\n" "$(yellow ○)"
fi
