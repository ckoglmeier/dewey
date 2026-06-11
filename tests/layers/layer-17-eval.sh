# ============================================================================
# LAYER 17: EVAL HARNESS HERMETIC CHECKS
# ============================================================================
# Always runs (no network, no model API). Verifies:
#   1. gen_cases.py is deterministic — regenerating produces identical output
#      (catches drift between in-tree skills and committed eval cases)
#   2. run_eval.py compiles cleanly and, with no backend, exits 77 (skip)
#   3. trigger_routing.jsonl: valid JSON lines; every expect_skill references
#      a real skill directory in plugins/
#   4. guide_flows.jsonl: valid JSON lines; required schema fields present
section "Layer 17 — Eval harness hermetic checks"

# ---- 1. gen_cases.py is deterministic ------------------------------------------

check "gen_cases.py regenerates trigger_routing.jsonl identically" "
  tmp=\$(mktemp)
  python3 '$REPO_ROOT/evals/gen_cases.py' --stdout > \"\$tmp\" 2>&1
  status=\$?
  if [ \$status -ne 0 ]; then
    cat \"\$tmp\"
    rm -f \"\$tmp\"
    exit 1
  fi
  diff -u '$REPO_ROOT/evals/cases/trigger_routing.jsonl' \"\$tmp\"
  rc=\$?
  rm -f \"\$tmp\"
  exit \$rc
"

# ---- 2. run_eval.py compiles and exits 77 with no backend ----------------------

check "run_eval.py compiles (syntax check)" "
  python3 -m py_compile '$REPO_ROOT/evals/run_eval.py'
"

check "run_eval.py exits 77 when DEWEY_EVAL is unset" "
  DEWEY_EVAL= python3 '$REPO_ROOT/evals/run_eval.py'
  rc=\$?
  [ \$rc -eq 77 ]
"

check "run_eval.py exits 77 when DEWEY_EVAL=1 but no backend configured" "
  DEWEY_EVAL=1 ANTHROPIC_API_KEY= DEWEY_EVAL_CMD= python3 '$REPO_ROOT/evals/run_eval.py'
  rc=\$?
  [ \$rc -eq 77 ]
"

check "run_eval.py skip message mentions DEWEY_EVAL=1 or backend instructions" "
  out=\$(DEWEY_EVAL= python3 '$REPO_ROOT/evals/run_eval.py' 2>&1)
  echo \"\$out\" | grep -qi 'DEWEY_EVAL'
"

# ---- 3. trigger_routing.jsonl: valid JSON lines, expect_skill references exist --

check "trigger_routing.jsonl is valid JSON lines (all lines parse)" "
  python3 - << 'EOF'
import json, sys
path = '$REPO_ROOT/evals/cases/trigger_routing.jsonl'
with open(path) as f:
    lines = [l for l in f if l.strip()]
errors = []
for i, line in enumerate(lines, 1):
    try:
        json.loads(line)
    except json.JSONDecodeError as e:
        errors.append(f'line {i}: {e}')
if errors:
    for e in errors:
        print('FAIL:', e)
    sys.exit(1)
print(f'ok: {len(lines)} lines parse cleanly')
EOF
"

check "trigger_routing.jsonl has required fields on every line" "
  python3 - << 'EOF'
import json, sys
path = '$REPO_ROOT/evals/cases/trigger_routing.jsonl'
required = {'skill', 'plugin', 'trigger', 'expect_skill'}
errors = []
with open(path) as f:
    for i, line in enumerate(f, 1):
        if not line.strip():
            continue
        d = json.loads(line)
        missing = required - set(d.keys())
        if missing:
            errors.append(f'line {i}: missing {missing}')
if errors:
    for e in errors:
        print('FAIL:', e)
    sys.exit(1)
print('ok: all lines have required fields')
EOF
"

check "trigger_routing.jsonl: every expect_skill is a real skill directory" "
  python3 - << 'EOF'
import json, os, sys
path = '$REPO_ROOT/evals/cases/trigger_routing.jsonl'
repo = '$REPO_ROOT'
errors = []
with open(path) as f:
    for i, line in enumerate(f, 1):
        if not line.strip():
            continue
        d = json.loads(line)
        plugin = d.get('plugin', '')
        skill = d.get('expect_skill', '')
        skill_dir = os.path.join(repo, 'plugins', plugin, 'skills', skill)
        if not os.path.isdir(skill_dir):
            errors.append(f'line {i}: no skill dir at plugins/{plugin}/skills/{skill}/')
if errors:
    for e in errors[:10]:
        print('FAIL:', e)
    if len(errors) > 10:
        print(f'...and {len(errors)-10} more')
    sys.exit(1)
print(f'ok: all expect_skill values reference real directories')
EOF
"

check "trigger_routing.jsonl has at least one case" "
  count=\$(python3 -c \"
import json
with open('$REPO_ROOT/evals/cases/trigger_routing.jsonl') as f:
    n = sum(1 for l in f if l.strip())
print(n)
\")
  [ \"\$count\" -gt 0 ]
"

# ---- 4. guide_flows.jsonl: valid JSON lines, required schema fields present -----

check "guide_flows.jsonl is valid JSON lines (all lines parse)" "
  python3 - << 'EOF'
import json, sys
path = '$REPO_ROOT/evals/cases/guide_flows.jsonl'
with open(path) as f:
    lines = [l for l in f if l.strip()]
errors = []
for i, line in enumerate(lines, 1):
    try:
        json.loads(line)
    except json.JSONDecodeError as e:
        errors.append(f'line {i}: {e}')
if errors:
    for e in errors:
        print('FAIL:', e)
    sys.exit(1)
print(f'ok: {len(lines)} lines parse cleanly')
EOF
"

check "guide_flows.jsonl has required fields (flow, persona, prompt, assert)" "
  python3 - << 'EOF'
import json, sys
path = '$REPO_ROOT/evals/cases/guide_flows.jsonl'
required = {'flow', 'persona', 'prompt', 'assert'}
errors = []
with open(path) as f:
    for i, line in enumerate(f, 1):
        if not line.strip():
            continue
        d = json.loads(line)
        missing = required - set(d.keys())
        if missing:
            errors.append(f'line {i}: missing {missing}')
        asserts = d.get('assert', [])
        if not isinstance(asserts, list) or len(asserts) == 0:
            errors.append(f'line {i}: assert must be a non-empty list')
if errors:
    for e in errors:
        print('FAIL:', e)
    sys.exit(1)
print('ok: all lines have required fields and non-empty assert lists')
EOF
"

check "guide_flows.jsonl has at least one case" "
  count=\$(python3 -c \"
import json
with open('$REPO_ROOT/evals/cases/guide_flows.jsonl') as f:
    n = sum(1 for l in f if l.strip())
print(n)
\")
  [ \"\$count\" -gt 0 ]
"

check "guide_flows.jsonl flow values are valid subcommands" "
  python3 - << 'EOF'
import json, sys
path = '$REPO_ROOT/evals/cases/guide_flows.jsonl'
valid_flows = {'recommend', 'install', 'extend', 'license', 'admin', 'propose',
               'curate-path', 'owners', 'update', 'analytics', 'sync', 'load', 'schedule'}
errors = []
with open(path) as f:
    for i, line in enumerate(f, 1):
        if not line.strip():
            continue
        d = json.loads(line)
        flow = d.get('flow', '')
        if flow not in valid_flows:
            errors.append(f'line {i}: unknown flow value {flow!r}')
if errors:
    for e in errors:
        print('FAIL:', e)
    sys.exit(1)
print('ok: all flow values are valid subcommand names')
EOF
"
