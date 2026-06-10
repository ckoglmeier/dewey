# ============================================================================
# LAYER 16: HOSTED SERVICE
# ============================================================================
section "Layer 16 — Hosted service"

# Python unittest suite
check "Layer 16: hosted unit+integration tests (test_hosted.py)" \
  "cd '$REPO_ROOT' && python3 -m unittest discover -s hosted/tests -q 2>&1 | tail -3"

# Structural checks
check "Layer 16: RUNBOOK.md exists" \
  "test -f '$REPO_ROOT/hosted/RUNBOOK.md'"

check "Layer 16: purchase-confirmation template exists" \
  "test -f '$REPO_ROOT/hosted/templates/purchase-confirmation.md'"

check "Layer 16: checkout-page template exists" \
  "test -f '$REPO_ROOT/hosted/templates/checkout-page.md'"

# Safety: no plaintext 'dwy_' key literals committed in the hosted package
# (fixture data in tests may contain the prefix, but never a full 36-char key)
check "Layer 16: no plaintext dwy_ license keys in hosted/ source" \
  "! grep -rn --include='*.py' --include='*.json' --include='*.md' \
     -E 'dwy_[0-9a-f]{32}' '$REPO_ROOT/hosted/'"
