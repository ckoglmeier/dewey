# ============================================================================
# LAYER 7: REFRESH SCRIPT
# ============================================================================
section "Layer 7 — Refresh script"

# Use the tarball sandbox from Layer 6 which has a refresh.sh installed.
REFRESH="$TARBALL_SANDBOX/.claude/dewey-refresh.sh"

check "refresh.sh exists and is executable" \
  "test -x '$REFRESH'"

# Force interval=0 so the marker doesn't gate the test, point at our local tarball.
run_refresh() {
  HOME="$TARBALL_SANDBOX" \
  DEWEY_DIR="$TARBALL_SANDBOX_DEWEY" \
  DEWEY_TARBALL="file://$TARBALL_FILE" \
  DEWEY_REFRESH_INTERVAL=0 \
  bash "$REFRESH"
}

check "refresh.sh runs cleanly when forced" \
  "run_refresh"

check "refresh.sh wrote a last-refresh marker" \
  "test -f '$TARBALL_SANDBOX/.claude/dewey-last-refresh'"

check "refresh.sh wrote a log entry" \
  "test -s '$TARBALL_SANDBOX/.claude/dewey-refresh.log'"

check "refresh.sh left no stale .old.* dirs" \
  "test ! -e '$TARBALL_SANDBOX_DEWEY.new' && ! ls -d '$TARBALL_SANDBOX_DEWEY'.old.* >/dev/null 2>&1"

# Lock-file blocks concurrent execution.
check "refresh.sh exits silently when lock file exists" \
  "
touch '$TARBALL_SANDBOX/.claude/dewey-refresh.lock'
HOME='$TARBALL_SANDBOX' DEWEY_DIR='$TARBALL_SANDBOX_DEWEY' DEWEY_TARBALL='file://$TARBALL_FILE' DEWEY_REFRESH_INTERVAL=0 bash '$REFRESH'
test \$? -eq 0
test -f '$TARBALL_SANDBOX/.claude/dewey-refresh.lock'
rm -f '$TARBALL_SANDBOX/.claude/dewey-refresh.lock'
"

# 24h marker honored: with default interval and a fresh marker, refresh should be a no-op.
check "refresh.sh skips when marker is fresh and interval is default" \
  "
touch '$TARBALL_SANDBOX/.claude/dewey-last-refresh'
out=\$(HOME='$TARBALL_SANDBOX' DEWEY_DIR='$TARBALL_SANDBOX_DEWEY' DEWEY_TARBALL='file://$TARBALL_FILE' bash '$REFRESH' 2>&1)
test -z \"\$out\"
"

# Disabled when interval is -1.
check "refresh.sh disabled with DEWEY_REFRESH_INTERVAL=-1" \
  "HOME='$TARBALL_SANDBOX' DEWEY_DIR='$TARBALL_SANDBOX_DEWEY' DEWEY_TARBALL='file://$TARBALL_FILE' DEWEY_REFRESH_INTERVAL=-1 bash '$REFRESH'"

# Network/extract failure must not break the cache or exit non-zero.
NETFAIL_LOG="$TARBALL_SANDBOX/.claude/dewey-refresh.log"
NETFAIL_BEFORE=$(wc -c < "$NETFAIL_LOG" 2>/dev/null || echo 0)
check "refresh.sh exits 0 on network failure (bad URL)" \
  "HOME='$TARBALL_SANDBOX' DEWEY_DIR='$TARBALL_SANDBOX_DEWEY' DEWEY_TARBALL='file:///nonexistent/path/that/does/not/exist.tar.gz' DEWEY_REFRESH_INTERVAL=0 bash '$REFRESH'"

check "refresh.sh logged the network failure" \
  "test \$(wc -c < '$NETFAIL_LOG') -gt $NETFAIL_BEFORE"

check "refresh.sh did NOT damage DEWEY_DIR after network failure" \
  "test -f '$TARBALL_SANDBOX_DEWEY/guide/SKILL.md'"

# Dev-checkout no-op: with .git/ present, refresh exits silently.
mkdir -p "$TARBALL_SANDBOX_DEWEY/.git"
check "refresh.sh is a no-op when DEWEY_DIR/.git exists" \
  "
out=\$(HOME='$TARBALL_SANDBOX' DEWEY_DIR='$TARBALL_SANDBOX_DEWEY' DEWEY_TARBALL='file://$TARBALL_FILE' DEWEY_REFRESH_INTERVAL=0 bash '$REFRESH' 2>&1)
test -z \"\$out\"
"
rm -rf "$TARBALL_SANDBOX_DEWEY/.git"
