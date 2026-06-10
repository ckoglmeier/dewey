# ============================================================================
# LAYER 15: TRIGGER & DESCRIPTION QUALITY
# ============================================================================
section "Layer 15 — Trigger & description quality"

check "Layer 15: triggers schema valid (check_triggers.py)" \
  "python3 '$REPO_ROOT/tests/lib/check_triggers.py' '$REPO_ROOT'"

check "Layer 15: description quality (check_description_quality.py)" \
  "python3 '$REPO_ROOT/tests/lib/check_description_quality.py' '$REPO_ROOT'"
