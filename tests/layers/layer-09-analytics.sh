# ============================================================================
# LAYER 9: ANALYTICS LOG
# ============================================================================
section "Layer 9 — Analytics log"

check "install.sh creates dewey-analytics.log when DEWEY_TELEMETRY != 0" \
  "test -f '$SANDBOX/.claude/dewey-analytics.log'"

check "dewey-analytics.log is a file (not dir, not symlink)" \
  "test -f '$SANDBOX/.claude/dewey-analytics.log' && test ! -L '$SANDBOX/.claude/dewey-analytics.log'"

# When telemetry is disabled, analytics log should NOT be created
NOTEL_SANDBOX="$(mktemp -d)"
NOTEL_DEWEY="$NOTEL_SANDBOX/.claude/dewey"
TMPDIRS_TO_CLEAN+=("$NOTEL_SANDBOX")
mkdir -p "$NOTEL_DEWEY"
cp -R "$REPO_ROOT/." "$NOTEL_DEWEY/"
check "install.sh does NOT create analytics log when DEWEY_TELEMETRY=0" \
  "
DEWEY_TELEMETRY=0 HOME='$NOTEL_SANDBOX' DEWEY_DIR='$NOTEL_DEWEY' \
  DEWEY_REPO='file://$REPO_ROOT' DEWEY_REF=main DEWEY_USE_INPLACE=1 \
  bash '$REPO_ROOT/install.sh' >/dev/null 2>&1
test ! -f '$NOTEL_SANDBOX/.claude/dewey-analytics.log'
"

# Any JSONL written to the log by the first-run hook must be valid JSON
check "first-run hook appends valid JSON to analytics log" \
  "
HOME='$SANDBOX' bash '$SANDBOX/.claude/dewey-first-run.sh' >/dev/null 2>&1
if [ -s '$SANDBOX/.claude/dewey-analytics.log' ]; then
  python3 -c '
import json, sys
with open(\"$SANDBOX/.claude/dewey-analytics.log\") as f:
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
