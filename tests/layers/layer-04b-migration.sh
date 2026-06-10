# ============================================================================
# LAYER 4b: CLASSROOM → DEWEY MIGRATION (sandbox)
# ============================================================================
# v2.0 install must hard-rename a prior Classroom install to Dewey:
# - ~/.claude/classroom/ → ~/.claude/dewey/
# - ~/.claude/skills/classroom/ → ~/.claude/skills/dewey/
# - ~/.claude/classroom-*.sh → removed (replaced by dewey-* helpers)
# - ~/.claude/classroom-{onboarded,first-run.sh,refresh.sh,...} → dewey-* equivalents
# - ~/.claude/classroom-analytics.log → ~/.claude/dewey-analytics.log (history preserved)
# - known_marketplaces.json: "classroom" key → "dewey", with paths updated
section "Layer 4b — Classroom→Dewey migration"

MIG_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$MIG_SANDBOX")
mkdir -p "$MIG_SANDBOX/.claude/skills/classroom" \
         "$MIG_SANDBOX/.claude/classroom" \
         "$MIG_SANDBOX/.claude/plugins"

# Pre-seed a fake old Classroom install
echo "old-cache-marker" > "$MIG_SANDBOX/.claude/classroom/marker"
echo "old-guide-content" > "$MIG_SANDBOX/.claude/skills/classroom/SKILL.md"
echo "old-analytics-line" > "$MIG_SANDBOX/.claude/classroom-analytics.log"
touch "$MIG_SANDBOX/.claude/classroom-onboarded"
echo "stub" > "$MIG_SANDBOX/.claude/classroom-refresh.sh"
echo "stub" > "$MIG_SANDBOX/.claude/classroom-propose.sh"
cat > "$MIG_SANDBOX/.claude/plugins/known_marketplaces.json" <<EOF
{
  "classroom": {
    "source": {"source": "directory", "path": "$MIG_SANDBOX/.claude/classroom"},
    "installLocation": "$MIG_SANDBOX/.claude/classroom",
    "lastUpdated": "2026-04-01T00:00:00Z"
  }
}
EOF

# Run install — should detect old paths and migrate
HOME="$MIG_SANDBOX" DEWEY_REPO="file://$REPO_ROOT" DEWEY_REF=main DEWEY_USE_INPLACE=1 \
  DEWEY_DIR="$MIG_SANDBOX/.claude/dewey" \
  bash "$REPO_ROOT/install.sh" >/dev/null 2>&1 || true

# But DEWEY_USE_INPLACE=1 means it won't fetch — for migration test we want the migration to run
# even when the cache itself is newly-arriving. Use the tarball path:
TARBALL_FILE2="$(mktemp -t dewey-mig.XXXXXX.tar.gz)"
TMPDIRS_TO_CLEAN+=("$(dirname "$TARBALL_FILE2")")
TARBALL_DIR2="$(mktemp -d)"
mkdir -p "$TARBALL_DIR2/stage/dewey-snapshot"
if command -v rsync >/dev/null 2>&1; then
  rsync -a --exclude='tests/' --exclude='.git/' "$REPO_ROOT/" "$TARBALL_DIR2/stage/dewey-snapshot/" 2>/dev/null
else
  cp -R "$REPO_ROOT/." "$TARBALL_DIR2/stage/dewey-snapshot/"
  rm -rf "$TARBALL_DIR2/stage/dewey-snapshot/tests" "$TARBALL_DIR2/stage/dewey-snapshot/.git"
fi
( cd "$TARBALL_DIR2/stage" && tar -czf "$TARBALL_FILE2" dewey-snapshot )
TMPDIRS_TO_CLEAN+=("$TARBALL_DIR2")

# Reset sandbox state for a clean run
rm -rf "$MIG_SANDBOX"
mkdir -p "$MIG_SANDBOX/.claude/skills/classroom" \
         "$MIG_SANDBOX/.claude/classroom" \
         "$MIG_SANDBOX/.claude/plugins"
echo "old-cache-marker" > "$MIG_SANDBOX/.claude/classroom/marker"
echo "old-guide-content" > "$MIG_SANDBOX/.claude/skills/classroom/SKILL.md"
echo "old-analytics-line" > "$MIG_SANDBOX/.claude/classroom-analytics.log"
touch "$MIG_SANDBOX/.claude/classroom-onboarded"
echo "stub" > "$MIG_SANDBOX/.claude/classroom-refresh.sh"
echo "stub" > "$MIG_SANDBOX/.claude/classroom-propose.sh"
cat > "$MIG_SANDBOX/.claude/plugins/known_marketplaces.json" <<EOF
{
  "classroom": {
    "source": {"source": "directory", "path": "$MIG_SANDBOX/.claude/classroom"},
    "installLocation": "$MIG_SANDBOX/.claude/classroom",
    "lastUpdated": "2026-04-01T00:00:00Z"
  }
}
EOF

HOME="$MIG_SANDBOX" DEWEY_REPO="$REPO_ROOT" DEWEY_REF=main DEWEY_TARBALL="file://$TARBALL_FILE2" \
  bash "$REPO_ROOT/install.sh" >/dev/null 2>&1

check "migration: ~/.claude/classroom/ renamed to ~/.claude/dewey/" \
  "test ! -e '$MIG_SANDBOX/.claude/classroom' && test -d '$MIG_SANDBOX/.claude/dewey'"

check "migration: ~/.claude/skills/classroom/ renamed to ~/.claude/skills/dewey/" \
  "test ! -e '$MIG_SANDBOX/.claude/skills/classroom' && test -d '$MIG_SANDBOX/.claude/skills/dewey'"

check "migration: classroom-analytics.log renamed to dewey-analytics.log (content preserved)" \
  "test ! -e '$MIG_SANDBOX/.claude/classroom-analytics.log' && \
   grep -q 'old-analytics-line' '$MIG_SANDBOX/.claude/dewey-analytics.log'"

check "migration: classroom-onboarded renamed to dewey-onboarded" \
  "test ! -e '$MIG_SANDBOX/.claude/classroom-onboarded' && test -e '$MIG_SANDBOX/.claude/dewey-onboarded'"

check "migration: old classroom-*.sh helpers removed" \
  "test ! -e '$MIG_SANDBOX/.claude/classroom-propose.sh' && \
   test ! -e '$MIG_SANDBOX/.claude/classroom-refresh.sh'"

check "migration: known_marketplaces.json 'classroom' key renamed to 'dewey'" \
  "python3 -c '
import json
d = json.load(open(\"$MIG_SANDBOX/.claude/plugins/known_marketplaces.json\"))
assert \"classroom\" not in d, \"classroom key still present\"
assert \"dewey\" in d, \"dewey key missing\"
loc = d[\"dewey\"][\"installLocation\"]
assert loc.endswith(\"/.claude/dewey\"), \"installLocation not migrated: \" + loc
'"

check "migration: dewey-migration.log records what was migrated" \
  "test -f '$MIG_SANDBOX/.claude/dewey-migration.log' && \
   grep -q 'classroom' '$MIG_SANDBOX/.claude/dewey-migration.log'"

# Idempotency: run install again; nothing more to migrate
HOME="$MIG_SANDBOX" DEWEY_REPO="$REPO_ROOT" DEWEY_REF=main DEWEY_TARBALL="file://$TARBALL_FILE2" \
  bash "$REPO_ROOT/install.sh" >/dev/null 2>&1

check "migration: re-running install is idempotent (no classroom paths reappear)" \
  "test ! -e '$MIG_SANDBOX/.claude/classroom' && \
   test ! -e '$MIG_SANDBOX/.claude/skills/classroom' && \
   test ! -e '$MIG_SANDBOX/.claude/classroom-analytics.log'"
