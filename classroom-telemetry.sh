#!/usr/bin/env bash
# Classroom telemetry helper — gated emit and forwarding strip
#
# Centralises the opt-out policy so every emit site uses the same gates.
#
# Usage:
#   classroom-telemetry.sh emit event=<name> [key=value ...]
#       Append a JSONL event to ~/.claude/classroom-analytics.log, gated by:
#         - $CLASSROOM_TELEMETRY=0          → suppress all
#         - plugin.json telemetry: false    → per-plugin opt-out
#         - SKILL.md telemetry: false       → per-skill opt-out
#       Recognised fields: event, parent, parent_plugin, parent_marketplace,
#       extension, additions, tools_added (comma-separated), user_intent,
#       skill, plugin, plugins (comma-separated), via, path.
#
#   classroom-telemetry.sh strip-bodies < in.jsonl > out.jsonl
#       Strip the prose fields (additions, user_intent) from extension_created
#       events unless $CLASSROOM_TELEMETRY_FORWARD_BODIES=1. Used by the
#       forwarder to enforce the body-opt-in privacy boundary.
#
# Env:
#   CLASSROOM_TELEMETRY                     0 = global off (default 1)
#   CLASSROOM_TELEMETRY_FORWARD_BODIES      1 = allow body fields through
#                                             strip-bodies (default 0)
#   CLASSROOM_DIR                           classroom cache root
#                                             (default ~/.claude/classroom)
#   CLASSROOM_LOG                           analytics log path
#                                             (default ~/.claude/classroom-analytics.log)

set -euo pipefail

CMD="${1:-}"
shift || true

CLASSROOM_DIR="${CLASSROOM_DIR:-$HOME/.claude/classroom}"
CLASSROOM_LOG="${CLASSROOM_LOG:-$HOME/.claude/classroom-analytics.log}"

case "$CMD" in
  emit)
    if [[ "${CLASSROOM_TELEMETRY:-1}" == "0" ]]; then
      exit 0
    fi
    python3 - "$CLASSROOM_DIR" "$CLASSROOM_LOG" "$@" <<'PY'
import json, os, sys, re
from datetime import datetime, timezone

classroom_dir, log_path, *kvs = sys.argv[1:]
fields = {}
for kv in kvs:
    k, _, v = kv.partition('=')
    fields[k] = v

# Per-plugin opt-out: read plugin.json telemetry field
plugin = fields.get('plugin') or fields.get('parent_plugin')
skill = fields.get('skill') or fields.get('parent')
if plugin:
    pj = os.path.join(classroom_dir, 'plugins', plugin, '.claude-plugin', 'plugin.json')
    if os.path.exists(pj):
        try:
            if json.load(open(pj)).get('telemetry') is False:
                sys.exit(0)
        except Exception:
            pass

# Per-skill opt-out: read SKILL.md frontmatter telemetry field
if plugin and skill:
    sm = os.path.join(classroom_dir, 'plugins', plugin, 'skills', skill, 'SKILL.md')
    if os.path.exists(sm):
        try:
            text = open(sm).read()
            m = re.match(r'^---\n(.*?)\n---', text, re.DOTALL)
            if m:
                for line in m.group(1).splitlines():
                    if re.match(r'^\s*telemetry\s*:\s*false\s*$', line):
                        sys.exit(0)
        except Exception:
            pass

event = fields.pop('event', None)
if not event:
    sys.exit(0)

obj = {
    'ts': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
    'event': event,
}
LIST_FIELDS = {'tools_added', 'plugins'}
for k, v in fields.items():
    if not v:
        continue
    if k in LIST_FIELDS:
        obj[k] = [s.strip() for s in v.split(',') if s.strip()]
    else:
        obj[k] = v

os.makedirs(os.path.dirname(log_path), exist_ok=True)
with open(log_path, 'a') as f:
    f.write(json.dumps(obj) + '\n')
PY
    ;;

  strip-bodies)
    python3 <(cat <<'PY'
import json, os, sys
allow = os.environ.get('CLASSROOM_TELEMETRY_FORWARD_BODIES') == '1'
SENSITIVE = ('additions', 'user_intent')
for line in sys.stdin:
    line = line.strip()
    if not line:
        continue
    try:
        obj = json.loads(line)
    except Exception:
        continue
    if obj.get('event') == 'extension_created' and not allow:
        for f in SENSITIVE:
            obj.pop(f, None)
    sys.stdout.write(json.dumps(obj) + '\n')
PY
)
    ;;

  ""|-h|--help)
    sed -n '2,25p' "$0"
    ;;

  *)
    printf "Unknown command: %s\n" "$CMD" >&2
    sed -n '2,25p' "$0" >&2
    exit 1
    ;;
esac
