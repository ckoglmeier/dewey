#!/usr/bin/env bash
# Dewey telemetry helper — gated emit, forwarding, and body strip
#
# Centralises the opt-out policy so every emit site uses the same gates.
#
# Usage:
#   dewey-telemetry.sh emit event=<name> [key=value ...]
#       Append a JSONL event to ~/.claude/dewey-analytics.log, gated by:
#         - $DEWEY_TELEMETRY=0          → suppress all
#         - plugin.json telemetry: false    → per-plugin opt-out
#         - SKILL.md telemetry: false       → per-skill opt-out
#       Recognised fields: event, parent, parent_plugin, parent_marketplace,
#       extension, additions, tools_added (comma-separated), user_intent,
#       skill, plugin, plugins (comma-separated), via, path.
#
#   dewey-telemetry.sh forward [--status]
#       Send locally-queued events to the hosted ingest endpoint.
#       Hard gates (checked in order): DEWEY_TELEMETRY=0, no
#       DEWEY_TELEMETRY_ENDPOINT, no ~/.claude/dewey-license. Any failure
#       exits 0 silently (never blocks or noises up a session).
#       Reads lines after the byte offset in ~/.claude/dewey-forward-offset
#       (default 0). On success advances the offset. Strips body fields
#       unless DEWEY_TELEMETRY_FORWARD_BODIES=1. Sends at most 500 lines
#       or 900 KB per run.
#
#       --status  Print endpoint/license/offset/pending-line-count; no network.
#
#   dewey-telemetry.sh strip-bodies < in.jsonl > out.jsonl
#       Strip the prose fields (additions, user_intent) from extension_created
#       events unless $DEWEY_TELEMETRY_FORWARD_BODIES=1. Used by the
#       forwarder to enforce the body-opt-in privacy boundary.
#
# Env:
#   DEWEY_TELEMETRY                     0 = global off (default 1)
#   DEWEY_TELEMETRY_FORWARD_BODIES      1 = allow body fields through
#                                             strip-bodies (default 0)
#   DEWEY_TELEMETRY_ENDPOINT            Base URL for the hosted ingest service
#                                             (e.g. https://api.dewey.example.com).
#                                             When unset forwarding is disabled.
#   DEWEY_DIR                           dewey cache root
#                                             (default ~/.claude/dewey)
#   DEWEY_LOG                           analytics log path
#                                             (default ~/.claude/dewey-analytics.log)
#   DEWEY_ORG                           org identifier included in every event;
#                                             falls back to ~/.claude/dewey-active-org
#                                             (first line), then "default"

set -euo pipefail

CMD="${1:-}"
shift || true

DEWEY_DIR="${DEWEY_DIR:-$HOME/.claude/dewey}"
DEWEY_LOG="${DEWEY_LOG:-$HOME/.claude/dewey-analytics.log}"

case "$CMD" in
  emit)
    if [[ "${DEWEY_TELEMETRY:-1}" == "0" ]]; then
      exit 0
    fi
    python3 - "$DEWEY_DIR" "$DEWEY_LOG" "$@" <<'PY'
import json, os, sys, re
from datetime import datetime, timezone

dewey_dir, log_path, *kvs = sys.argv[1:]
fields = {}
for kv in kvs:
    k, _, v = kv.partition('=')
    fields[k] = v

# Org resolution: $DEWEY_ORG env > ~/.claude/dewey-active-org file > "default"
org = os.environ.get('DEWEY_ORG', '').strip()
if not org:
    active_org_path = os.path.join(os.path.expanduser('~'), '.claude', 'dewey-active-org')
    if os.path.exists(active_org_path):
        try:
            org = open(active_org_path).readline().strip()
        except Exception:
            pass
if not org:
    org = 'default'

# Per-plugin opt-out: read plugin.json telemetry field
plugin = fields.get('plugin') or fields.get('parent_plugin')
skill = fields.get('skill') or fields.get('parent')
if plugin:
    pj = os.path.join(dewey_dir, 'plugins', plugin, '.claude-plugin', 'plugin.json')
    if os.path.exists(pj):
        try:
            if json.load(open(pj)).get('telemetry') is False:
                sys.exit(0)
        except Exception:
            pass

# Per-skill opt-out: read SKILL.md frontmatter telemetry field
if plugin and skill:
    sm = os.path.join(dewey_dir, 'plugins', plugin, 'skills', skill, 'SKILL.md')
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

# Install ID: read from ~/.claude/dewey-install-id if present (generation is
# install-time only; hand-built environments without the file emit no ID).
install_id = None
install_id_path = os.path.join(os.path.expanduser('~'), '.claude', 'dewey-install-id')
if os.path.exists(install_id_path):
    try:
        install_id = open(install_id_path).readline().strip()
        if not install_id:
            install_id = None
    except Exception:
        install_id = None

obj = {
    'ts': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
    'event': event,
    'org': org,
}
if install_id:
    obj['install_id'] = install_id
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

  forward)
    # Hard gates — checked in order, all exit 0 silently.
    if [[ "${DEWEY_TELEMETRY:-1}" == "0" ]]; then
      exit 0
    fi

    _ENDPOINT="${DEWEY_TELEMETRY_ENDPOINT:-}"
    _LICENSE_FILE="$HOME/.claude/dewey-license"
    _OFFSET_FILE="$HOME/.claude/dewey-forward-offset"
    _REFRESH_LOG="$HOME/.claude/dewey-refresh.log"

    # --status: print state without network
    if [[ "${1:-}" == "--status" ]]; then
      if [[ -n "$_ENDPOINT" ]]; then
        printf "endpoint: %s\n" "$_ENDPOINT"
      else
        printf "endpoint: (not set)\n"
      fi
      if [[ -f "$_LICENSE_FILE" ]]; then
        printf "license: present\n"
      else
        printf "license: (not found)\n"
      fi
      _cur_offset=0
      if [[ -f "$_OFFSET_FILE" ]]; then
        _cur_offset="$(cat "$_OFFSET_FILE" 2>/dev/null || echo 0)"
      fi
      printf "offset: %s\n" "$_cur_offset"
      if [[ -f "$DEWEY_LOG" ]]; then
        _log_size="$(wc -c < "$DEWEY_LOG" 2>/dev/null || echo 0)"
        _pending_lines=0
        if [[ "$_log_size" -gt "$_cur_offset" ]]; then
          _pending_lines="$(tail -c +"$(( _cur_offset + 1 ))" "$DEWEY_LOG" 2>/dev/null | grep -c . || echo 0)"
        fi
        printf "pending-lines: %s\n" "$_pending_lines"
      else
        printf "pending-lines: 0\n"
      fi
      exit 0
    fi

    # No endpoint → nothing to do.
    if [[ -z "$_ENDPOINT" ]]; then
      exit 0
    fi

    # No license file → nothing to do.
    if [[ ! -f "$_LICENSE_FILE" ]]; then
      exit 0
    fi

    _license_key="$(cat "$_LICENSE_FILE" 2>/dev/null || true)"
    if [[ -z "$_license_key" ]]; then
      exit 0
    fi

    # No log → nothing to forward.
    if [[ ! -f "$DEWEY_LOG" ]]; then
      exit 0
    fi

    # Read current offset (default 0).
    _offset=0
    if [[ -f "$_OFFSET_FILE" ]]; then
      _offset="$(cat "$_OFFSET_FILE" 2>/dev/null || echo 0)"
      # Ensure it's a non-negative integer.
      if ! [[ "$_offset" =~ ^[0-9]+$ ]]; then
        _offset=0
      fi
    fi

    _log_size="$(wc -c < "$DEWEY_LOG" 2>/dev/null || echo 0)"
    if [[ "$_log_size" -le "$_offset" ]]; then
      exit 0
    fi

    # Extract pending lines after the byte offset, capped at 500 lines / 900 KB.
    # Use python3 for portable byte-offset slicing and batch capping.
    _batch_file="$(mktemp)"
    _new_offset="$(python3 - "$DEWEY_LOG" "$_offset" "$_batch_file" <<'PY'
import sys
log_path, offset_str, out_path = sys.argv[1], sys.argv[2], sys.argv[3]
offset = int(offset_str)
MAX_LINES = 500
MAX_BYTES = 900 * 1024

with open(log_path, 'rb') as f:
    f.seek(offset)
    data = f.read()

lines = []
byte_count = 0
for raw in data.split(b'\n'):
    if not raw.strip():
        continue
    line_bytes = raw + b'\n'
    if len(lines) >= MAX_LINES or byte_count + len(line_bytes) > MAX_BYTES:
        break
    lines.append(raw.decode('utf-8', errors='replace'))
    byte_count += len(line_bytes)

with open(out_path, 'w') as f:
    for line in lines:
        f.write(line.rstrip('\n') + '\n')

consumed = sum(len(l.encode('utf-8', errors='replace')) + 1 for l in lines)
print(offset + consumed)
PY
    2>/dev/null)" || { rm -f "$_batch_file"; exit 0; }

    if [[ ! -s "$_batch_file" ]]; then
      rm -f "$_batch_file"
      exit 0
    fi

    # Apply body strip (reuse existing strip-bodies logic via pipe).
    _stripped_file="$(mktemp)"
    DEWEY_TELEMETRY_FORWARD_BODIES="${DEWEY_TELEMETRY_FORWARD_BODIES:-0}" \
      bash "$0" strip-bodies < "$_batch_file" > "$_stripped_file" 2>/dev/null \
      || { rm -f "$_batch_file" "$_stripped_file"; exit 0; }

    if [[ ! -s "$_stripped_file" ]]; then
      rm -f "$_batch_file" "$_stripped_file"
      # Nothing to send (all lines stripped?), but still advance offset.
      printf "%s" "$_new_offset" > "$_OFFSET_FILE" 2>/dev/null || true
      exit 0
    fi

    # POST to the ingest endpoint with the license key as bearer.
    _http_response="$(curl -s -o /dev/null -w "%{http_code}" \
      --max-time 15 \
      -X POST \
      -H "Authorization: Bearer ${_license_key}" \
      -H "Content-Type: application/x-ndjson" \
      --data-binary "@${_stripped_file}" \
      "${_ENDPOINT%/}/v1/events" 2>/dev/null)" || _http_response=""

    rm -f "$_batch_file" "$_stripped_file"

    if [[ "$_http_response" == "200" ]]; then
      printf "%s" "$_new_offset" > "$_OFFSET_FILE" 2>/dev/null || true
    else
      # On failure: log one line to dewey-refresh.log (not user-facing), exit 0.
      printf '[%s] forward: non-200 response (%s) — will retry next run\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${_http_response:-network-error}" \
        >> "$_REFRESH_LOG" 2>/dev/null || true
    fi
    exit 0
    ;;

  strip-bodies)
    python3 <(cat <<'PY'
import json, os, sys
allow = os.environ.get('DEWEY_TELEMETRY_FORWARD_BODIES') == '1'
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
    sed -n '2,60p' "$0"
    ;;

  *)
    printf "Unknown command: %s\n" "$CMD" >&2
    sed -n '2,60p' "$0" >&2
    exit 1
    ;;
esac
