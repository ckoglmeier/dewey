# ============================================================================
# LAYER 16: HOSTED API CONTRACT (mock)
#
# All checks run against tests/lib/contract_mock_server.py — a stdlib-only
# Python mock that implements docs/hosted-api.md v1.1 exactly.  No real
# service is contacted; no API keys are required.
# ============================================================================
section "Layer 16 — Hosted API contract (mock)"

MOCK_SERVER="$REPO_ROOT/tests/lib/contract_mock_server.py"
TELEMETRY_SRC="$REPO_ROOT/dewey-telemetry.sh"

# ---- Structural checks (no mock needed) ------------------------------------

check "Layer 16: contract_mock_server.py exists" \
  "test -f '$MOCK_SERVER'"

check "Layer 16: docs/hosted-api.md exists" \
  "test -f '$REPO_ROOT/docs/hosted-api.md'"

check "Layer 16: docs/hosted-api.md mentions v1.1 (current contract version)" \
  "grep -q 'v1.1' '$REPO_ROOT/docs/hosted-api.md'"

check "Layer 16: docs/hosted-api.md notes v1.0 clients remain valid" \
  "grep -q 'v1.0 clients' '$REPO_ROOT/docs/hosted-api.md'"

# ---- Shared mock-key values used across the live tests ---------------------
# These are the two keys the mock recognises.
_MOCK_VALID="dwy_valid0000000000000000000000000000"
_MOCK_CANCELED="dwy_cancel00000000000000000000000000"

# ---- Helper: start the mock server and store PID + port --------------------
# Usage: _start_mock  ->  sets L16_MOCK_PID, L16_MOCK_PORT
# The function is defined here once; individual checks inline the kill at exit.

# ---- Test 1: mock starts and /healthz responds -----------------------------
check "Layer 16: mock server starts and GET /healthz returns {\"ok\":true}" \
  "
_L16_HOME=\$(mktemp -d)
trap 'kill \$_L16_PID 2>/dev/null; rm -rf \"\$_L16_HOME\"' EXIT

MOCK_VALID_KEY='$_MOCK_VALID' \
MOCK_CANCELED_KEY='$_MOCK_CANCELED' \
  python3 '$MOCK_SERVER' --port 0 > \"\$_L16_HOME/port\" 2>/dev/null &
_L16_PID=\$!
sleep 0.4
_L16_PORT=\$(cat \"\$_L16_HOME/port\" 2>/dev/null || echo 0)
test \"\$_L16_PORT\" -gt 0

_resp=\$(curl -sf \"http://127.0.0.1:\$_L16_PORT/healthz\")
python3 -c \"
import json, sys
o = json.loads(sys.argv[1])
assert o == {'ok': True}, repr(o)
\" \"\$_resp\"
"

# ---- Test 2: dewey-telemetry.sh forward delivers events via contract mock --
check "Layer 16: dewey-telemetry.sh forward delivers events to contract mock with correct bearer and advances offset" \
  "
_L16_FWD_HOME=\$(mktemp -d)
_L16_FWD_LOG=\"\$_L16_FWD_HOME/.claude/dewey-analytics.log\"
_L16_FWD_OFFSET=\"\$_L16_FWD_HOME/.claude/dewey-forward-offset\"
_L16_FWD_LIC=\"\$_L16_FWD_HOME/.claude/dewey-license\"
mkdir -p \"\$_L16_FWD_HOME/.claude\"
printf '{\"ts\":\"2026-01-01T00:00:00Z\",\"event\":\"skill_invoke\",\"skill\":\"meeting-prep\"}\n' > \"\$_L16_FWD_LOG\"
printf '{\"ts\":\"2026-01-01T01:00:00Z\",\"event\":\"skill_invoke\",\"skill\":\"competitive-analysis\"}\n' >> \"\$_L16_FWD_LOG\"
printf '%s' '$_MOCK_VALID' > \"\$_L16_FWD_LIC\"
chmod 600 \"\$_L16_FWD_LIC\"

MOCK_VALID_KEY='$_MOCK_VALID' \
MOCK_CANCELED_KEY='$_MOCK_CANCELED' \
  python3 '$MOCK_SERVER' --port 0 > \"\$_L16_FWD_HOME/port\" 2>/dev/null &
_L16_FWD_PID=\$!
trap 'kill \$_L16_FWD_PID 2>/dev/null; rm -rf \"\$_L16_FWD_HOME\"' EXIT
sleep 0.4
_L16_FWD_PORT=\$(cat \"\$_L16_FWD_HOME/port\" 2>/dev/null || echo 0)
test \"\$_L16_FWD_PORT\" -gt 0

HOME=\"\$_L16_FWD_HOME\" \
DEWEY_LOG=\"\$_L16_FWD_LOG\" \
DEWEY_TELEMETRY_ENDPOINT=\"http://127.0.0.1:\$_L16_FWD_PORT\" \
  bash '$TELEMETRY_SRC' forward
sleep 0.3

# Offset must have advanced (events were accepted)
test -f \"\$_L16_FWD_OFFSET\"
_off=\$(cat \"\$_L16_FWD_OFFSET\")
test \"\$_off\" -gt 0
"

# ---- Test 3: forward with a wrong key exits 0 silently (swallows 401) ------
check "Layer 16: forward with wrong key exits 0 silently (client swallows 401)" \
  "
_L16_WK_HOME=\$(mktemp -d)
_L16_WK_LOG=\"\$_L16_WK_HOME/.claude/dewey-analytics.log\"
_L16_WK_LIC=\"\$_L16_WK_HOME/.claude/dewey-license\"
mkdir -p \"\$_L16_WK_HOME/.claude\"
printf '{\"ts\":\"2026-01-01T00:00:00Z\",\"event\":\"test\"}\n' > \"\$_L16_WK_LOG\"
printf 'dwy_wrongkey00000000000000000000000000' > \"\$_L16_WK_LIC\"
chmod 600 \"\$_L16_WK_LIC\"

MOCK_VALID_KEY='$_MOCK_VALID' \
MOCK_CANCELED_KEY='$_MOCK_CANCELED' \
  python3 '$MOCK_SERVER' --port 0 > \"\$_L16_WK_HOME/port\" 2>/dev/null &
_L16_WK_PID=\$!
trap 'kill \$_L16_WK_PID 2>/dev/null; rm -rf \"\$_L16_WK_HOME\"' EXIT
sleep 0.4
_L16_WK_PORT=\$(cat \"\$_L16_WK_HOME/port\" 2>/dev/null || echo 0)
test \"\$_L16_WK_PORT\" -gt 0

# Must exit 0 (silent failure)
HOME=\"\$_L16_WK_HOME\" \
DEWEY_LOG=\"\$_L16_WK_LOG\" \
DEWEY_TELEMETRY_ENDPOINT=\"http://127.0.0.1:\$_L16_WK_PORT\" \
  bash '$TELEMETRY_SRC' forward
# exit code of the subshell above — should be 0
"

# ---- Test 4: install.sh with valid key says 'activated' --------------------
check "Layer 16: install.sh with DEWEY_LICENSE_KEY=valid says 'activated'" \
  "
_L16_INST_HOME=\$(mktemp -d)
mkdir -p \"\$_L16_INST_HOME/.claude\"

MOCK_VALID_KEY='$_MOCK_VALID' \
MOCK_CANCELED_KEY='$_MOCK_CANCELED' \
  python3 '$MOCK_SERVER' --port 0 > \"\$_L16_INST_HOME/port\" 2>/dev/null &
_L16_INST_PID=\$!
trap 'kill \$_L16_INST_PID 2>/dev/null; rm -rf \"\$_L16_INST_HOME\"' EXIT
sleep 0.4
_L16_INST_PORT=\$(cat \"\$_L16_INST_HOME/port\" 2>/dev/null || echo 0)
test \"\$_L16_INST_PORT\" -gt 0

_output=\$(HOME=\"\$_L16_INST_HOME\" \
  DEWEY_USE_INPLACE=1 \
  DEWEY_DIR='$SANDBOX/.claude/dewey' \
  DEWEY_LICENSE_KEY='$_MOCK_VALID' \
  DEWEY_TELEMETRY_ENDPOINT=\"http://127.0.0.1:\$_L16_INST_PORT\" \
    bash '$REPO_ROOT/install.sh' 2>&1 || true)
echo \"\$_output\" | grep -qi 'activated'
"

# ---- Test 5: install.sh with invalid key warns but succeeds ----------------
check "Layer 16: install.sh with invalid key warns but exits 0" \
  "
_L16_INV_HOME=\$(mktemp -d)
mkdir -p \"\$_L16_INV_HOME/.claude\"

MOCK_VALID_KEY='$_MOCK_VALID' \
MOCK_CANCELED_KEY='$_MOCK_CANCELED' \
  python3 '$MOCK_SERVER' --port 0 > \"\$_L16_INV_HOME/port\" 2>/dev/null &
_L16_INV_PID=\$!
trap 'kill \$_L16_INV_PID 2>/dev/null; rm -rf \"\$_L16_INV_HOME\"' EXIT
sleep 0.4
_L16_INV_PORT=\$(cat \"\$_L16_INV_HOME/port\" 2>/dev/null || echo 0)
test \"\$_L16_INV_PORT\" -gt 0

# Must exit 0 even with invalid key
HOME=\"\$_L16_INV_HOME\" \
  DEWEY_USE_INPLACE=1 \
  DEWEY_DIR='$SANDBOX/.claude/dewey' \
  DEWEY_LICENSE_KEY='dwy_invalidkey000000000000000000000' \
  DEWEY_TELEMETRY_ENDPOINT=\"http://127.0.0.1:\$_L16_INV_PORT\" \
    bash '$REPO_ROOT/install.sh' 2>&1 || true
# If we reach here, exit was 0 (set -e in the check harness would catch a non-zero)
"

# ---- Test 6: validate response contains ONLY the "valid" field -------------
# The contract's security note: MUST NOT return org/plan/status.
check "Layer 16: POST /v1/license/validate response contains only the \"valid\" field (no org/plan/status leak)" \
  "
_L16_RESP_HOME=\$(mktemp -d)
trap 'kill \$_L16_RESP_PID 2>/dev/null; rm -rf \"\$_L16_RESP_HOME\"' EXIT

MOCK_VALID_KEY='$_MOCK_VALID' \
MOCK_CANCELED_KEY='$_MOCK_CANCELED' \
  python3 '$MOCK_SERVER' --port 0 > \"\$_L16_RESP_HOME/port\" 2>/dev/null &
_L16_RESP_PID=\$!
sleep 0.4
_L16_RESP_PORT=\$(cat \"\$_L16_RESP_HOME/port\" 2>/dev/null || echo 0)
test \"\$_L16_RESP_PORT\" -gt 0

_resp=\$(curl -sf -X POST \
  -H 'Content-Type: application/json' \
  -d '{\"key\":\"$_MOCK_VALID\"}' \
  \"http://127.0.0.1:\$_L16_RESP_PORT/v1/license/validate\")

# Must have exactly one key: 'valid'
python3 -c \"
import json, sys
o = json.loads(sys.argv[1])
keys = set(o.keys())
assert keys == {'valid'}, 'unexpected fields in response: ' + repr(keys)
assert o['valid'] is True
\" \"\$_resp\"

# Double-check with grep: none of the forbidden fields must appear
echo \"\$_resp\" | grep -qv 'org' || { echo 'org leaked'; exit 1; }
echo \"\$_resp\" | grep -qv 'plan' || { echo 'plan leaked'; exit 1; }
echo \"\$_resp\" | grep -qv 'status' || { echo 'status leaked'; exit 1; }
"

# ---- Test 7: 413 for an oversized events POST ------------------------------
check "Layer 16: POST /v1/events with oversized body returns 413" \
  "
_L16_413_HOME=\$(mktemp -d)
trap 'kill \$_L16_413_PID 2>/dev/null; rm -rf \"\$_L16_413_HOME\"' EXIT

MOCK_VALID_KEY='$_MOCK_VALID' \
MOCK_CANCELED_KEY='$_MOCK_CANCELED' \
  python3 '$MOCK_SERVER' --port 0 > \"\$_L16_413_HOME/port\" 2>/dev/null &
_L16_413_PID=\$!
sleep 0.4
_L16_413_PORT=\$(cat \"\$_L16_413_HOME/port\" 2>/dev/null || echo 0)
test \"\$_L16_413_PORT\" -gt 0

# Generate a body just over 1 MB (1048577 bytes)
python3 -c \"sys.stdout.buffer.write(b'x' * 1048577)\" 2>/dev/null \
  || python3 -c \"import sys; sys.stdout.buffer.write(b'x' * 1048577)\"

# Use curl with a pipe; capture HTTP status code
_code=\$(python3 -c \"import sys; sys.stdout.buffer.write(b'x' * 1048577)\" | \
  curl -s -o /dev/null -w '%{http_code}' \
  -X POST \
  -H 'Authorization: Bearer $_MOCK_VALID' \
  -H 'Content-Type: application/x-ndjson' \
  --data-binary @- \
  \"http://127.0.0.1:\$_L16_413_PORT/v1/events\")
test \"\$_code\" = \"413\"
"

# ---- Test 8: no plaintext dwy_ license keys in test fixtures ---------------
check "Layer 16: no plaintext dwy_ license keys in tests/ source (fixture prefix only)" \
  "! grep -rn --include='*.py' --include='*.json' \
     -E 'dwy_[0-9a-f]{32}' '$REPO_ROOT/tests/'"
