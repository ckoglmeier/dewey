# ============================================================================
# LAYER 15: TRIGGER & DESCRIPTION QUALITY
# ============================================================================
section "Layer 15 — Trigger & description quality"

check "Layer 15: triggers schema valid (check_triggers.py)" \
  "python3 '$REPO_ROOT/tests/lib/check_triggers.py' '$REPO_ROOT'"

check "Layer 15: description quality (check_description_quality.py)" \
  "python3 '$REPO_ROOT/tests/lib/check_description_quality.py' '$REPO_ROOT'"

# when_to_use is generated from triggers; a hand edit to either must be re-synced
check "Layer 15: when_to_use mirrors triggers in every skill (sync-when-to-use.py --check)" \
  "python3 '$REPO_ROOT/scripts/sync-when-to-use.py' --check"
