# ============================================================================
# LAYER 12: EXTENSION TELEMETRY (helper, gates, schema, body-strip)
# ============================================================================
section "Layer 12 — Extension telemetry"

TELEMETRY_SRC="$REPO_ROOT/dewey-telemetry.sh"

check "dewey-telemetry.sh exists" \
  "test -f '$TELEMETRY_SRC'"

check "dewey-telemetry.sh has clean bash syntax" \
  "bash -n '$TELEMETRY_SRC'"

# Build a sandbox Dewey cache with one demo plugin + skill
TELEM_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$TELEM_SANDBOX")
TELEM_CACHE="$TELEM_SANDBOX/dewey"
TELEM_LOG="$TELEM_SANDBOX/log"
mkdir -p "$TELEM_CACHE/plugins/demo/.claude-plugin" "$TELEM_CACHE/plugins/demo/skills/foo"
printf '{"name":"demo"}\n' > "$TELEM_CACHE/plugins/demo/.claude-plugin/plugin.json"
printf -- "---\nname: foo\ndescription: x\n---\nbody\n" > "$TELEM_CACHE/plugins/demo/skills/foo/SKILL.md"

# Basic emit lands a JSONL line with required fields
check "emit appends a JSON line with ts, event, and provided fields" \
  "
DEWEY_DIR='$TELEM_CACHE' DEWEY_LOG='$TELEM_LOG' \
  bash '$TELEMETRY_SRC' emit event=test_event plugin=demo parent=foo additions='hello' tools_added='Bash(*),mcp:linear'
test -f '$TELEM_LOG'
python3 -c '
import json
line = open(\"$TELEM_LOG\").read().splitlines()[-1]
o = json.loads(line)
assert o[\"event\"] == \"test_event\"
assert o[\"plugin\"] == \"demo\"
assert o[\"parent\"] == \"foo\"
assert o[\"additions\"] == \"hello\"
assert o[\"tools_added\"] == [\"Bash(*)\", \"mcp:linear\"]
assert \"ts\" in o
'
"

# Global opt-out: DEWEY_TELEMETRY=0 suppresses
TELEM_LOG2="$TELEM_SANDBOX/log2"
check "DEWEY_TELEMETRY=0 suppresses emit (no log file created)" \
  "
DEWEY_TELEMETRY=0 DEWEY_DIR='$TELEM_CACHE' DEWEY_LOG='$TELEM_LOG2' \
  bash '$TELEMETRY_SRC' emit event=test plugin=demo
test ! -e '$TELEM_LOG2'
"

# Plugin-level opt-out: telemetry: false on plugin.json
TELEM_CACHE2="$TELEM_SANDBOX/dewey2"
TELEM_LOG3="$TELEM_SANDBOX/log3"
mkdir -p "$TELEM_CACHE2/plugins/demo/.claude-plugin" "$TELEM_CACHE2/plugins/demo/skills/foo"
printf '{"name":"demo","telemetry":false}\n' > "$TELEM_CACHE2/plugins/demo/.claude-plugin/plugin.json"
printf -- "---\nname: foo\n---\nbody\n" > "$TELEM_CACHE2/plugins/demo/skills/foo/SKILL.md"
check "plugin telemetry: false suppresses emit (no log file)" \
  "
DEWEY_DIR='$TELEM_CACHE2' DEWEY_LOG='$TELEM_LOG3' \
  bash '$TELEMETRY_SRC' emit event=test plugin=demo parent=foo
test ! -e '$TELEM_LOG3'
"

# Skill-level opt-out: telemetry: false in SKILL.md frontmatter (plugin allows)
TELEM_CACHE3="$TELEM_SANDBOX/dewey3"
TELEM_LOG4="$TELEM_SANDBOX/log4"
mkdir -p "$TELEM_CACHE3/plugins/demo/.claude-plugin" "$TELEM_CACHE3/plugins/demo/skills/foo"
printf '{"name":"demo"}\n' > "$TELEM_CACHE3/plugins/demo/.claude-plugin/plugin.json"
printf -- "---\nname: foo\ntelemetry: false\n---\nbody\n" > "$TELEM_CACHE3/plugins/demo/skills/foo/SKILL.md"
check "skill telemetry: false suppresses emit (no log file)" \
  "
DEWEY_DIR='$TELEM_CACHE3' DEWEY_LOG='$TELEM_LOG4' \
  bash '$TELEMETRY_SRC' emit event=test plugin=demo parent=foo
test ! -e '$TELEM_LOG4'
"

# strip-bodies removes additions/user_intent from extension_created by default
check "strip-bodies removes additions and user_intent by default" \
  "
out=\$(printf '%s\n' \
    '{\"event\":\"extension_created\",\"parent\":\"foo\",\"additions\":\"secret\",\"user_intent\":\"a\",\"tools_added\":[\"x\"]}' \
    '{\"event\":\"skill_install\",\"skill\":\"y\"}' \
  | bash '$TELEMETRY_SRC' strip-bodies)
echo \"\$out\" | python3 -c '
import json, sys
lines = sys.stdin.read().splitlines()
assert len(lines) == 2
ext = json.loads(lines[0])
assert ext[\"event\"] == \"extension_created\"
assert \"additions\" not in ext
assert \"user_intent\" not in ext
assert ext[\"tools_added\"] == [\"x\"]
inst = json.loads(lines[1])
assert inst[\"event\"] == \"skill_install\"
'
"

# strip-bodies with FORWARD_BODIES=1 preserves
check "DEWEY_TELEMETRY_FORWARD_BODIES=1 preserves additions and user_intent" \
  "
out=\$(echo '{\"event\":\"extension_created\",\"parent\":\"foo\",\"additions\":\"secret\",\"user_intent\":\"a\"}' \
  | DEWEY_TELEMETRY_FORWARD_BODIES=1 bash '$TELEMETRY_SRC' strip-bodies)
echo \"\$out\" | python3 -c '
import json, sys
o = json.loads(sys.stdin.read())
assert o[\"additions\"] == \"secret\"
assert o[\"user_intent\"] == \"a\"
'
"

# Org field — default value
TELEM_LOG_ORG_DEFAULT="$TELEM_SANDBOX/log-org-default"
check "org field defaults to \"default\" when DEWEY_ORG is unset and no active-org file" \
  "
unset DEWEY_ORG
DEWEY_DIR='$TELEM_CACHE' DEWEY_LOG='$TELEM_LOG_ORG_DEFAULT' \
  bash '$TELEMETRY_SRC' emit event=test_org_default plugin=demo parent=foo
python3 -c '
import json
line = open(\"$TELEM_LOG_ORG_DEFAULT\").read().splitlines()[-1]
o = json.loads(line)
assert o[\"org\"] == \"default\", repr(o.get(\"org\"))
'
"

# Org field — DEWEY_ORG env var
TELEM_LOG_ORG_ENV="$TELEM_SANDBOX/log-org-env"
check "DEWEY_ORG=acme sets org field to \"acme\" in emitted event" \
  "
DEWEY_ORG=acme DEWEY_DIR='$TELEM_CACHE' DEWEY_LOG='$TELEM_LOG_ORG_ENV' \
  bash '$TELEMETRY_SRC' emit event=test_org_env plugin=demo parent=foo
python3 -c '
import json
line = open(\"$TELEM_LOG_ORG_ENV\").read().splitlines()[-1]
o = json.loads(line)
assert o[\"org\"] == \"acme\", repr(o.get(\"org\"))
'
"

# Org field — ~/.claude/dewey-active-org file (DEWEY_ORG unset)
TELEM_LOG_ORG_FILE="$TELEM_SANDBOX/log-org-file"
TELEM_FAKE_HOME="$TELEM_SANDBOX/fake-home"
mkdir -p "$TELEM_FAKE_HOME/.claude"
printf 'task-engineering\n' > "$TELEM_FAKE_HOME/.claude/dewey-active-org"
check "dewey-active-org file value appears in org field when DEWEY_ORG is unset" \
  "
unset DEWEY_ORG
HOME='$TELEM_FAKE_HOME' DEWEY_DIR='$TELEM_CACHE' DEWEY_LOG='$TELEM_LOG_ORG_FILE' \
  bash '$TELEMETRY_SRC' emit event=test_org_file plugin=demo parent=foo
python3 -c '
import json
line = open(\"$TELEM_LOG_ORG_FILE\").read().splitlines()[-1]
o = json.loads(line)
assert o[\"org\"] == \"task-engineering\", repr(o.get(\"org\"))
'
"

# install.sh installs dewey-telemetry.sh
INSTALLED_TELEM="$SANDBOX/.claude/dewey-telemetry.sh"
check "install.sh installs dewey-telemetry.sh to \$HOME/.claude" \
  "test -f '$INSTALLED_TELEM' && test -x '$INSTALLED_TELEM'"

check "installed dewey-telemetry.sh has clean bash syntax" \
  "bash -n '$INSTALLED_TELEM'"

# Guide §3 calls the helper for extension_created
check "guide/SKILL.md §3 calls dewey-telemetry.sh emit for extension_created" \
  "grep -A1 -E '^## §3' '$REPO_ROOT/guide/SKILL.md' >/dev/null
grep -q 'dewey-telemetry.sh emit' '$REPO_ROOT/guide/SKILL.md'
grep -q 'event=extension_created' '$REPO_ROOT/guide/SKILL.md'"

# docs/extension-telemetry.md exists
check "docs/extension-telemetry.md exists" \
  "test -f '$REPO_ROOT/docs/extension-telemetry.md'"

check "docs/extension-telemetry.md describes 3 privacy layers" \
  "grep -q 'DEWEY_TELEMETRY=0' '$REPO_ROOT/docs/extension-telemetry.md' &&
   grep -q 'telemetry: false' '$REPO_ROOT/docs/extension-telemetry.md' &&
   grep -q 'DEWEY_TELEMETRY_FORWARD_BODIES' '$REPO_ROOT/docs/extension-telemetry.md'"

# ============================================================================
# LAYER 12b: forward subcommand tests
# ============================================================================
section "Layer 12b — forward subcommand"

# Build a sandbox for forward tests
FWD_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$FWD_SANDBOX")
FWD_HOME="$FWD_SANDBOX/home"
FWD_LOG="$FWD_HOME/.claude/dewey-analytics.log"
FWD_OFFSET="$FWD_HOME/.claude/dewey-forward-offset"
FWD_LICENSE="$FWD_HOME/.claude/dewey-license"
mkdir -p "$FWD_HOME/.claude"

# forward with no endpoint exits 0 silently
check "forward with no endpoint exits 0 silently" \
  "
printf '%s\n' '{\"ts\":\"2026-01-01T00:00:00Z\",\"event\":\"test\"}' > '$FWD_LOG'
HOME='$FWD_HOME' \
DEWEY_LOG='$FWD_LOG' \
DEWEY_TELEMETRY_ENDPOINT='' \
  bash '$TELEMETRY_SRC' forward
"

# forward with no license file exits 0 silently
check "forward with no license file exits 0 silently" \
  "
HOME='$FWD_HOME' \
DEWEY_LOG='$FWD_LOG' \
DEWEY_TELEMETRY_ENDPOINT='http://127.0.0.1:29999' \
  bash '$TELEMETRY_SRC' forward
"

# DEWEY_TELEMETRY=0 exits 0 even with endpoint + license
check "DEWEY_TELEMETRY=0 suppresses forward even with endpoint and license" \
  "
printf 'dwy_aabbccdd11223344aabbccdd11223344' > '$FWD_LICENSE'
chmod 600 '$FWD_LICENSE'
DEWEY_TELEMETRY=0 \
HOME='$FWD_HOME' \
DEWEY_LOG='$FWD_LOG' \
DEWEY_TELEMETRY_ENDPOINT='http://127.0.0.1:29999' \
  bash '$TELEMETRY_SRC' forward
"

# forward --status prints expected keys without network
check "forward --status prints endpoint/license/offset/pending-lines" \
  "
HOME='$FWD_HOME' \
DEWEY_LOG='$FWD_LOG' \
DEWEY_TELEMETRY_ENDPOINT='http://127.0.0.1:29999' \
  bash '$TELEMETRY_SRC' forward --status | grep -q 'endpoint:'
HOME='$FWD_HOME' \
DEWEY_LOG='$FWD_LOG' \
DEWEY_TELEMETRY_ENDPOINT='http://127.0.0.1:29999' \
  bash '$TELEMETRY_SRC' forward --status | grep -q 'license:'
HOME='$FWD_HOME' \
DEWEY_LOG='$FWD_LOG' \
DEWEY_TELEMETRY_ENDPOINT='http://127.0.0.1:29999' \
  bash '$TELEMETRY_SRC' forward --status | grep -q 'offset:'
HOME='$FWD_HOME' \
DEWEY_LOG='$FWD_LOG' \
DEWEY_TELEMETRY_ENDPOINT='http://127.0.0.1:29999' \
  bash '$TELEMETRY_SRC' forward --status | grep -q 'pending-lines:'
"

# forward with mock server: delivers right lines, right Authorization header, advances offset
check "forward delivers events to mock server with correct Authorization header and advances offset" \
  "
# Write test events to a fresh log
FWD_MOCK_HOME=\$(mktemp -d)
FWD_MOCK_LOG=\"\$FWD_MOCK_HOME/.claude/dewey-analytics.log\"
FWD_MOCK_OFFSET=\"\$FWD_MOCK_HOME/.claude/dewey-forward-offset\"
FWD_MOCK_LICENSE=\"\$FWD_MOCK_HOME/.claude/dewey-license\"
FWD_MOCK_CAPTURE=\"\$FWD_MOCK_HOME/capture\"
mkdir -p \"\$FWD_MOCK_HOME/.claude\"
printf '{\"ts\":\"2026-01-01T00:00:00Z\",\"event\":\"skill_invoke\",\"skill\":\"meeting-prep\"}\n' > \"\$FWD_MOCK_LOG\"
printf '{\"ts\":\"2026-01-01T01:00:00Z\",\"event\":\"skill_invoke\",\"skill\":\"competitive-analysis\"}\n' >> \"\$FWD_MOCK_LOG\"
printf 'dwy_aabbccdd11223344aabbccdd11223344' > \"\$FWD_MOCK_LICENSE\"
chmod 600 \"\$FWD_MOCK_LICENSE\"

# Start a mock HTTP server on an ephemeral port using python3 stdlib.
# It writes the raw request headers+body to a capture file, then responds 200.
python3 -c \"
import http.server, threading, os, sys

capture_path = sys.argv[1]

class Handler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(length)
        with open(capture_path, 'wb') as f:
            header_lines = []
            for k, v in self.headers.items():
                header_lines.append(k + ': ' + v)
            f.write(('\n'.join(header_lines) + '\n\n').encode())
            f.write(body)
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(b'{\\\"accepted\\\":2}')
    def log_message(self, *a):
        pass

server = http.server.HTTPServer(('127.0.0.1', 0), Handler)
port = server.server_address[1]
print(port, flush=True)
# Serve exactly one request then exit.
server.handle_request()
\" \"\$FWD_MOCK_CAPTURE\" > \"\$FWD_MOCK_HOME/port\" 2>/dev/null &
MOCK_PID=\$!
trap 'kill \$MOCK_PID 2>/dev/null || true' EXIT

# Give the server a moment to bind.
sleep 0.3
MOCK_PORT=\$(cat \"\$FWD_MOCK_HOME/port\" 2>/dev/null || echo 0)
test \"\$MOCK_PORT\" -gt 0

# Run forward against the mock server.
HOME=\"\$FWD_MOCK_HOME\" \
DEWEY_LOG=\"\$FWD_MOCK_LOG\" \
DEWEY_TELEMETRY_ENDPOINT=\"http://127.0.0.1:\$MOCK_PORT\" \
  bash '$TELEMETRY_SRC' forward

# Give the server time to write capture file.
sleep 0.3

# Verify: Authorization header present with correct bearer.
grep -qi 'Authorization: Bearer dwy_aabbccdd11223344aabbccdd11223344' \"\$FWD_MOCK_CAPTURE\"

# Verify: offset advanced (should be > 0).
test -f \"\$FWD_MOCK_OFFSET\"
_off=\$(cat \"\$FWD_MOCK_OFFSET\")
test \"\$_off\" -gt 0

kill \$MOCK_PID 2>/dev/null || true
rm -rf \"\$FWD_MOCK_HOME\"
"

# Second run sends nothing new (offset covers all lines)
check "second forward run sends nothing new when offset is at end of log" \
  "
FWD_SECOND_HOME=\$(mktemp -d)
FWD_SECOND_LOG=\"\$FWD_SECOND_HOME/.claude/dewey-analytics.log\"
FWD_SECOND_OFFSET=\"\$FWD_SECOND_HOME/.claude/dewey-forward-offset\"
FWD_SECOND_LICENSE=\"\$FWD_SECOND_HOME/.claude/dewey-license\"
FWD_SECOND_CAPTURE=\"\$FWD_SECOND_HOME/capture\"
mkdir -p \"\$FWD_SECOND_HOME/.claude\"
printf '{\"ts\":\"2026-01-01T00:00:00Z\",\"event\":\"skill_invoke\"}\n' > \"\$FWD_SECOND_LOG\"
printf 'dwy_aabbccdd11223344aabbccdd11223344' > \"\$FWD_SECOND_LICENSE\"
chmod 600 \"\$FWD_SECOND_LICENSE\"

# Start a mock that counts requests.
python3 -c \"
import http.server, sys

count_path = sys.argv[1]

class Handler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get('Content-Length', 0))
        self.rfile.read(length)
        # Increment request count
        try:
            n = int(open(count_path).read())
        except Exception:
            n = 0
        open(count_path, 'w').write(str(n + 1))
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(b'{\\\"accepted\\\":1}')
    def log_message(self, *a):
        pass

server = http.server.HTTPServer(('127.0.0.1', 0), Handler)
port = server.server_address[1]
print(port, flush=True)
open(count_path, 'w').write('0')
# Serve up to 2 requests.
server.handle_request()
server.handle_request()
\" \"\$FWD_SECOND_CAPTURE\" > \"\$FWD_SECOND_HOME/port\" 2>/dev/null &
MOCK2_PID=\$!
trap 'kill \$MOCK2_PID 2>/dev/null || true' EXIT

sleep 0.3
MOCK2_PORT=\$(cat \"\$FWD_SECOND_HOME/port\" 2>/dev/null || echo 0)
test \"\$MOCK2_PORT\" -gt 0

# First forward: should send 1 event.
HOME=\"\$FWD_SECOND_HOME\" \
DEWEY_LOG=\"\$FWD_SECOND_LOG\" \
DEWEY_TELEMETRY_ENDPOINT=\"http://127.0.0.1:\$MOCK2_PORT\" \
  bash '$TELEMETRY_SRC' forward
sleep 0.3
_count1=\$(cat \"\$FWD_SECOND_CAPTURE\" 2>/dev/null || echo 0)
test \"\$_count1\" -eq 1

# Second forward: offset is at end, nothing to send — server request count stays at 1.
HOME=\"\$FWD_SECOND_HOME\" \
DEWEY_LOG=\"\$FWD_SECOND_LOG\" \
DEWEY_TELEMETRY_ENDPOINT=\"http://127.0.0.1:\$MOCK2_PORT\" \
  bash '$TELEMETRY_SRC' forward
sleep 0.1
_count2=\$(cat \"\$FWD_SECOND_CAPTURE\" 2>/dev/null || echo 0)
test \"\$_count2\" -eq 1

kill \$MOCK2_PID 2>/dev/null || true
rm -rf \"\$FWD_SECOND_HOME\"
"

# Bodies stripped by default (additions/user_intent absent in forwarded payload)
check "forward strips body fields (additions, user_intent) from extension_created by default" \
  "
FWD_BODIES_HOME=\$(mktemp -d)
FWD_BODIES_LOG=\"\$FWD_BODIES_HOME/.claude/dewey-analytics.log\"
FWD_BODIES_LICENSE=\"\$FWD_BODIES_HOME/.claude/dewey-license\"
FWD_BODIES_CAPTURE=\"\$FWD_BODIES_HOME/capture\"
mkdir -p \"\$FWD_BODIES_HOME/.claude\"
printf '{\"ts\":\"2026-01-01T00:00:00Z\",\"event\":\"extension_created\",\"parent\":\"foo\",\"additions\":\"secret stuff\",\"user_intent\":\"do things\"}\n' > \"\$FWD_BODIES_LOG\"
printf 'dwy_aabbccdd11223344aabbccdd11223344' > \"\$FWD_BODIES_LICENSE\"
chmod 600 \"\$FWD_BODIES_LICENSE\"

python3 -c \"
import http.server, sys

capture_path = sys.argv[1]

class Handler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(length)
        open(capture_path, 'wb').write(body)
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(b'{\\\"accepted\\\":1}')
    def log_message(self, *a):
        pass

server = http.server.HTTPServer(('127.0.0.1', 0), Handler)
port = server.server_address[1]
print(port, flush=True)
server.handle_request()
\" \"\$FWD_BODIES_CAPTURE\" > \"\$FWD_BODIES_HOME/port\" 2>/dev/null &
MOCK3_PID=\$!
trap 'kill \$MOCK3_PID 2>/dev/null || true' EXIT

sleep 0.3
MOCK3_PORT=\$(cat \"\$FWD_BODIES_HOME/port\" 2>/dev/null || echo 0)
test \"\$MOCK3_PORT\" -gt 0

HOME=\"\$FWD_BODIES_HOME\" \
DEWEY_LOG=\"\$FWD_BODIES_LOG\" \
DEWEY_TELEMETRY_ENDPOINT=\"http://127.0.0.1:\$MOCK3_PORT\" \
  bash '$TELEMETRY_SRC' forward
sleep 0.3

# Captured body must NOT contain the sensitive fields.
python3 -c \"
import json
body = open('\$FWD_BODIES_CAPTURE', 'rb').read()
# parse JSONL line(s)
for line in body.split(b'\n'):
    line = line.strip()
    if not line:
        continue
    obj = json.loads(line)
    assert 'additions' not in obj, 'additions leaked: ' + repr(obj)
    assert 'user_intent' not in obj, 'user_intent leaked: ' + repr(obj)
\"

kill \$MOCK3_PID 2>/dev/null || true
rm -rf \"\$FWD_BODIES_HOME\"
"

# DEWEY_TELEMETRY_FORWARD_BODIES=1 preserves body fields in forwarded payload
check "DEWEY_TELEMETRY_FORWARD_BODIES=1 sends additions and user_intent to endpoint" \
  "
FWD_FB_HOME=\$(mktemp -d)
FWD_FB_LOG=\"\$FWD_FB_HOME/.claude/dewey-analytics.log\"
FWD_FB_LICENSE=\"\$FWD_FB_HOME/.claude/dewey-license\"
FWD_FB_CAPTURE=\"\$FWD_FB_HOME/capture\"
mkdir -p \"\$FWD_FB_HOME/.claude\"
printf '{\"ts\":\"2026-01-01T00:00:00Z\",\"event\":\"extension_created\",\"parent\":\"foo\",\"additions\":\"public stuff\",\"user_intent\":\"do public things\"}\n' > \"\$FWD_FB_LOG\"
printf 'dwy_aabbccdd11223344aabbccdd11223344' > \"\$FWD_FB_LICENSE\"
chmod 600 \"\$FWD_FB_LICENSE\"

python3 -c \"
import http.server, sys

capture_path = sys.argv[1]

class Handler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(length)
        open(capture_path, 'wb').write(body)
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(b'{\\\"accepted\\\":1}')
    def log_message(self, *a):
        pass

server = http.server.HTTPServer(('127.0.0.1', 0), Handler)
port = server.server_address[1]
print(port, flush=True)
server.handle_request()
\" \"\$FWD_FB_CAPTURE\" > \"\$FWD_FB_HOME/port\" 2>/dev/null &
MOCK4_PID=\$!
trap 'kill \$MOCK4_PID 2>/dev/null || true' EXIT

sleep 0.3
MOCK4_PORT=\$(cat \"\$FWD_FB_HOME/port\" 2>/dev/null || echo 0)
test \"\$MOCK4_PORT\" -gt 0

HOME=\"\$FWD_FB_HOME\" \
DEWEY_LOG=\"\$FWD_FB_LOG\" \
DEWEY_TELEMETRY_ENDPOINT=\"http://127.0.0.1:\$MOCK4_PORT\" \
DEWEY_TELEMETRY_FORWARD_BODIES=1 \
  bash '$TELEMETRY_SRC' forward
sleep 0.3

python3 -c \"
import json
body = open('\$FWD_FB_CAPTURE', 'rb').read()
for line in body.split(b'\n'):
    line = line.strip()
    if not line:
        continue
    obj = json.loads(line)
    assert obj.get('additions') == 'public stuff', 'additions missing: ' + repr(obj)
    assert obj.get('user_intent') == 'do public things', 'user_intent missing: ' + repr(obj)
\"

kill \$MOCK4_PID 2>/dev/null || true
rm -rf \"\$FWD_FB_HOME\"
"
