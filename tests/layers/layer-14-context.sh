# ============================================================================
# LAYER 14: CANONICAL CONTEXT (schema, ID resolution, body alignment, size,
#                              surface compatibility, extension targets)
# ============================================================================
section "Layer 14 — Canonical context"

# Schema validation: every plugin.json's `context` array (if present) is well-formed
for plugin_dir in plugins/*/; do
  plugin_name=$(basename "$plugin_dir")
  manifest="$plugin_dir.claude-plugin/plugin.json"

  check "[$plugin_name] context entries are well-formed (if present)" \
    "python3 -c '
import json, os, re, sys
manifest = \"$manifest\"
plugin_dir = \"$plugin_dir\"
plugin_name = \"$plugin_name\"
p = json.load(open(manifest))
valid_surfaces = {\"claude-code\", \"cowork\", \"codex\", \"chat\"}
plugin_surfaces = p.get(\"surfaces\") or [\"claude-code\"]
ctx = p.get(\"context\")
if ctx is None: sys.exit(0)
assert isinstance(ctx, list), \"context must be a list\"
seen = set()
for entry in ctx:
    assert isinstance(entry, dict), \"context entry must be an object\"
    for required in (\"id\", \"path\", \"title\"):
        assert entry.get(required), f\"context entry missing required field: {required}\"
        assert isinstance(entry.get(required), str), f\"context field {required} must be a string\"
    cid = entry[\"id\"]
    assert cid.count(\"/\") == 1, f\"context id must be <plugin>/<bundle>: {cid}\"
    pseg, bseg = cid.split(\"/\", 1)
    assert pseg == plugin_name, f\"context id plugin segment {pseg!r} must match containing plugin {plugin_name!r}\"
    assert re.fullmatch(r\"[a-z0-9]+(-[a-z0-9]+)*\", bseg), f\"context id bundle segment must be kebab-case: {cid}\"
    assert cid not in seen, f\"duplicate context id: {cid}\"
    seen.add(cid)
    rel = entry[\"path\"]
    assert not rel.startswith(\"/\") and \"..\" not in rel.split(\"/\"), f\"context path must be relative without ..: {rel}\"
    assert rel.startswith(\"context/\"), f\"context path must live under context/: {rel}\"
    full = os.path.join(plugin_dir, rel)
    assert os.path.exists(full), f\"context path does not exist: {full}\"
    if \"description\" in entry:
        assert isinstance(entry[\"description\"], str), \"context description must be a string\"
    if \"allow-large-context\" in entry:
        assert isinstance(entry[\"allow-large-context\"], bool), \"allow-large-context must be boolean\"
    surfaces = entry.get(\"surfaces\")
    if surfaces is not None:
        assert isinstance(surfaces, list), \"context surfaces must be a list\"
        assert len(surfaces) > 0, \"context surfaces must be non-empty\"
        for s in surfaces:
            assert s in valid_surfaces, f\"invalid context surface: {s}\"
        assert set(surfaces).issubset(set(plugin_surfaces)), \"context surfaces must be a subset of plugin surfaces\"
'"

  check "[$plugin_name] context files respect size limits" \
    "python3 -c '
import json, os, sys
manifest = \"$manifest\"
plugin_dir = \"$plugin_dir\"
p = json.load(open(manifest))
ctx = p.get(\"context\") or []
WARN = 20 * 1024
FAIL = 100 * 1024
def files_under(root):
    if os.path.isfile(root): yield root; return
    for dp, _, fns in os.walk(root):
        for fn in fns:
            yield os.path.join(dp, fn)
for entry in ctx:
    full = os.path.join(plugin_dir, entry[\"path\"])
    allow_large = bool(entry.get(\"allow-large-context\"))
    for f in files_under(full):
        if not f.endswith(\".md\"):
            sys.exit(f\"{f} is inside a context bundle but is not markdown\")
        size = os.path.getsize(f)
        if size > FAIL and not allow_large:
            sys.exit(f\"{f} exceeds 100KB ({size} bytes); set allow-large-context: true on the entry to permit\")
'"
done

# Per-skill: requires-context resolves, appears in body, surface compat
for plugin_dir in plugins/*/; do
  plugin_name=$(basename "$plugin_dir")
  for skill_md in "$plugin_dir"skills/*/SKILL.md; do
    [ -f "$skill_md" ] || continue
    skill_rel="${skill_md#$REPO_ROOT/}"

    check "[$skill_rel] requires-context: IDs resolve, appear in body, surfaces compatible" \
      "python3 '$REPO_ROOT/tests/lib/check_requires_context.py' '$skill_md' '$plugin_dir' '$plugin_name'"
  done
done

# Demonstrator content exists end-to-end
check "competitive-intelligence positioning context file exists" \
  "test -f '$REPO_ROOT/plugins/competitive-intelligence/context/positioning/context.md'"

check "competitive-analysis declares requires-context: positioning" \
  "grep -q 'competitive-intelligence/positioning' '$REPO_ROOT/plugins/competitive-intelligence/skills/competitive-analysis/SKILL.md'"

# Negative-case fixtures: validator catches drift, missing IDs, and missing extension targets
LAYER14_FIXTURES="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$LAYER14_FIXTURES")
mkdir -p "$LAYER14_FIXTURES/plugins/demo/.claude-plugin" \
         "$LAYER14_FIXTURES/plugins/demo/skills/foo" \
         "$LAYER14_FIXTURES/plugins/demo/context/bar"
printf '%s\n' \
  '{"name":"demo","surfaces":["claude-code","cowork","codex","chat"],"context":[{"id":"demo/bar","path":"context/bar/bar.md","title":"Bar"}]}' \
  > "$LAYER14_FIXTURES/plugins/demo/.claude-plugin/plugin.json"
printf '%s\n' "stub bar context" > "$LAYER14_FIXTURES/plugins/demo/context/bar/bar.md"

# Case A: skill declares requires-context for an unknown ID
mkdir -p "$LAYER14_FIXTURES/plugins/demo/skills/skill_a"
cat > "$LAYER14_FIXTURES/plugins/demo/skills/skill_a/SKILL.md" <<'EOF'
---
name: skill_a
description: declares unknown
requires-context:
  - demo/nonexistent
---
First, load demo/nonexistent.

Body.
EOF

check "[fixture] validator rejects unknown requires-context id" \
  "
cd '$LAYER14_FIXTURES' && \
  ! python3 '$REPO_ROOT/tests/lib/check_requires_context.py' \
      'plugins/demo/skills/skill_a/SKILL.md' \
      'plugins/demo/' \
      'demo' >/dev/null 2>&1
"

# Case B: skill declares requires-context but body never references the id
mkdir -p "$LAYER14_FIXTURES/plugins/demo/skills/skill_b"
cat > "$LAYER14_FIXTURES/plugins/demo/skills/skill_b/SKILL.md" <<'EOF'
---
name: skill_b
description: drift case
requires-context:
  - demo/bar
---
This body never mentions the context.
EOF

check "[fixture] validator rejects frontmatter/body drift" \
  "
cd '$LAYER14_FIXTURES' && \
  ! python3 '$REPO_ROOT/tests/lib/check_requires_context.py' \
      'plugins/demo/skills/skill_b/SKILL.md' \
      'plugins/demo/' \
      'demo' >/dev/null 2>&1
"

# Case C: context extension targets an unknown ID
mkdir -p "$LAYER14_FIXTURES/plugins/demo/skills/skill_c"
cat > "$LAYER14_FIXTURES/plugins/demo/skills/skill_c/SKILL.md" <<'EOF'
---
name: skill_c
description: bad extension target
extends-context: demo/missing
---
This extends a missing context bundle.
EOF

check "[fixture] validator rejects unknown extends-context target" \
  "
cd '$LAYER14_FIXTURES' && \
  ! python3 '$REPO_ROOT/tests/lib/check_requires_context.py' \
      'plugins/demo/skills/skill_c/SKILL.md' \
      'plugins/demo/' \
      'demo' >/dev/null 2>&1
"

# Naming convention: every in-tree context entry's primary path ends in context.md
for plugin_dir in plugins/*/; do
  plugin_name=$(basename "$plugin_dir")

  check "[$plugin_name] context entries use the context.md primary-file convention" \
    "python3 '$REPO_ROOT/tests/lib/check_context_naming.py' '$plugin_dir'"
done

# Guide §11 Load: section exists and references the load mechanic
check "guide/SKILL.md §11 Load is present and documents the load flow" \
  "grep -q '## §11 Load' '$REPO_ROOT/guide/SKILL.md' &&
   grep -q '/dewey load' '$REPO_ROOT/guide/SKILL.md' &&
   grep -q 'context.md' '$REPO_ROOT/guide/SKILL.md'"

check "guide argument-hint includes load" \
  "grep -q 'load' '$REPO_ROOT/guide/SKILL.md' &&
   head -20 '$REPO_ROOT/guide/SKILL.md' | grep -q 'argument-hint.*load'"
