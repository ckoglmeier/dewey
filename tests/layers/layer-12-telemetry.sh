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
