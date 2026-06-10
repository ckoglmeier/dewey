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

# ---- Refresh channel tests (no network) -------------------------------------
# Build dynamic fixtures that point at our local test tarball (file:// URLs),
# so the release channel logic runs end-to-end without any real network access.

RELEASE_FIXTURE_DIR="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$RELEASE_FIXTURE_DIR")
STATIC_FIXTURE_DIR="$REPO_ROOT/tests/fixtures/release-api"

# Fixture: valid release with both asset + checksum asset pointing at local tarball.
# The checksum asset URL is a file:// path — resolve_release() in the refresh
# script fetches it via curl, which supports file:// natively.
RELEASE_SHA256_FILE="$RELEASE_FIXTURE_DIR/dewey-v99.0.0.tar.gz.sha256"
echo "$TARBALL_SHA  dewey-v99.0.0.tar.gz" > "$RELEASE_SHA256_FILE"

python3 - "$RELEASE_FIXTURE_DIR" "$TARBALL_FILE" "$RELEASE_SHA256_FILE" <<'PY'
import json, sys
out_dir, tarball, sha256_file = sys.argv[1], sys.argv[2], sys.argv[3]
d = {
    "tag_name": "v99.0.0",
    "name": "Dewey v99.0.0",
    "draft": False,
    "prerelease": False,
    "assets": [
        {
            "name": "dewey-v99.0.0.tar.gz",
            "browser_download_url": f"file://{tarball}"
        },
        {
            "name": "dewey-v99.0.0.tar.gz.sha256",
            "browser_download_url": f"file://{sha256_file}"
        }
    ]
}
with open(f"{out_dir}/release-with-file-urls.json", "w") as f:
    json.dump(d, f, indent=2)
PY

# Also update the static fixture companion file (used by layer-06 unit tests).
echo "$TARBALL_SHA  dewey-v99.0.0.tar.gz" > "$STATIC_FIXTURE_DIR/dewey-v99.0.0.tar.gz.sha256"

# Build a second sandbox for the release-channel tests so we don't pollute
# TARBALL_SANDBOX which other tests in this layer depend on.
# Install via DEWEY_USE_INPLACE so no DEWEY_TARBALL is baked into the refresh script —
# the release channel needs to drive the URL from the API fixture, not an override.
RELEASE_CH_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$RELEASE_CH_SANDBOX")
RELEASE_CH_DEWEY="$RELEASE_CH_SANDBOX/.claude/dewey"
mkdir -p "$RELEASE_CH_DEWEY"
cp -R "$TARBALL_SANDBOX_DEWEY/." "$RELEASE_CH_DEWEY/"
HOME="$RELEASE_CH_SANDBOX" \
DEWEY_DIR="$RELEASE_CH_DEWEY" \
DEWEY_REPO="https://example.invalid/dewey" \
DEWEY_REF="main" \
DEWEY_USE_INPLACE=1 \
bash "$REPO_ROOT/install.sh" >/dev/null 2>&1

RELEASE_CH_REFRESH="$RELEASE_CH_SANDBOX/.claude/dewey-refresh.sh"

# release channel: fixture with file:// URLs for both assets; checksum matches.
# The refresh should succeed and update the cache.
check "refresh.sh (release channel) succeeds with valid fixture and matching checksum" \
  "HOME='$RELEASE_CH_SANDBOX' \
   DEWEY_DIR='$RELEASE_CH_DEWEY' \
   DEWEY_REFRESH_INTERVAL=0 \
   DEWEY_REFRESH_CHANNEL=release \
   DEWEY_RESOLVE_RELEASE_JSON='$RELEASE_FIXTURE_DIR/release-with-file-urls.json' \
   bash '$RELEASE_CH_REFRESH'"

check "refresh.sh (release channel) wrote a log entry" \
  "test -s '$RELEASE_CH_SANDBOX/.claude/dewey-refresh.log'"

check "refresh.sh (release channel) preserved guide/SKILL.md after swap" \
  "test -f '$RELEASE_CH_DEWEY/guide/SKILL.md'"

# release channel: when checksum asset is missing from fixture, the refresh
# must decline the swap (exit 0 but NOT replace the cache).
# Install with DEWEY_USE_INPLACE so no DEWEY_TARBALL is baked into the refresh
# script — that way the release-channel logic actually runs in the test.
DECLINE_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$DECLINE_SANDBOX")
DECLINE_DEWEY="$DECLINE_SANDBOX/.claude/dewey"
mkdir -p "$DECLINE_DEWEY"
cp -R "$TARBALL_SANDBOX_DEWEY/." "$DECLINE_DEWEY/"
HOME="$DECLINE_SANDBOX" \
DEWEY_DIR="$DECLINE_DEWEY" \
DEWEY_REPO="https://example.invalid/dewey" \
DEWEY_REF="main" \
DEWEY_USE_INPLACE=1 \
bash "$REPO_ROOT/install.sh" >/dev/null 2>&1

DECLINE_REFRESH="$DECLINE_SANDBOX/.claude/dewey-refresh.sh"

check "refresh.sh (release channel) declines swap when checksum asset is absent" \
  "HOME='$DECLINE_SANDBOX' \
   DEWEY_DIR='$DECLINE_DEWEY' \
   DEWEY_REFRESH_INTERVAL=0 \
   DEWEY_REFRESH_CHANNEL=release \
   DEWEY_RESOLVE_RELEASE_JSON='$FIXTURE_DIR/release-no-checksum-asset.json' \
   bash '$DECLINE_REFRESH'"

check "refresh.sh (release channel) logged the decline" \
  "grep -q 'declining' '$DECLINE_SANDBOX/.claude/dewey-refresh.log'"

check "refresh.sh (release channel) left DEWEY_DIR intact after decline" \
  "test -f '$DECLINE_DEWEY/guide/SKILL.md'"

# release channel: wrong checksum must also decline and leave cache intact.
BADSHA_REFRESH_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$BADSHA_REFRESH_SANDBOX")
BADSHA_REFRESH_DEWEY="$BADSHA_REFRESH_SANDBOX/.claude/dewey"
mkdir -p "$BADSHA_REFRESH_DEWEY"
cp -R "$TARBALL_SANDBOX_DEWEY/." "$BADSHA_REFRESH_DEWEY/"
HOME="$BADSHA_REFRESH_SANDBOX" \
DEWEY_DIR="$BADSHA_REFRESH_DEWEY" \
DEWEY_REPO="https://example.invalid/dewey" \
DEWEY_REF="main" \
DEWEY_USE_INPLACE=1 \
bash "$REPO_ROOT/install.sh" >/dev/null 2>&1

BADSHA_REFRESH="$BADSHA_REFRESH_SANDBOX/.claude/dewey-refresh.sh"

# Build a fixture where the checksum file contains a wrong hash but the
# tarball URL points at our real local tarball (so the download works,
# but the hash check fails). This exercises the mismatch path.
WRONG_SHA_DIR="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$WRONG_SHA_DIR")
WRONG_SHA_FILE="$WRONG_SHA_DIR/dewey-v99.0.0.tar.gz.sha256"
echo "0000000000000000000000000000000000000000000000000000000000000000  dewey-v99.0.0.tar.gz" > "$WRONG_SHA_FILE"
python3 - "$WRONG_SHA_DIR" "$TARBALL_FILE" "$WRONG_SHA_FILE" <<'PY'
import json, sys
out_dir, tarball, sha256_file = sys.argv[1], sys.argv[2], sys.argv[3]
d = {
    "tag_name": "v99.0.0",
    "name": "Dewey v99.0.0",
    "draft": False,
    "prerelease": False,
    "assets": [
        {"name": "dewey-v99.0.0.tar.gz", "browser_download_url": f"file://{tarball}"},
        {"name": "dewey-v99.0.0.tar.gz.sha256", "browser_download_url": f"file://{sha256_file}"}
    ]
}
with open(f"{out_dir}/release-bad-sha.json", "w") as f:
    json.dump(d, f, indent=2)
PY

check "refresh.sh (release channel) declines swap when checksum mismatches" \
  "HOME='$BADSHA_REFRESH_SANDBOX' \
   DEWEY_DIR='$BADSHA_REFRESH_DEWEY' \
   DEWEY_REFRESH_INTERVAL=0 \
   DEWEY_REFRESH_CHANNEL=release \
   DEWEY_RESOLVE_RELEASE_JSON='$WRONG_SHA_DIR/release-bad-sha.json' \
   bash '$BADSHA_REFRESH'"

check "refresh.sh bad-checksum decline left DEWEY_DIR intact" \
  "test -f '$BADSHA_REFRESH_DEWEY/guide/SKILL.md'"

# main channel: still works (no checksum required).
MAIN_CH_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$MAIN_CH_SANDBOX")
MAIN_CH_DEWEY="$MAIN_CH_SANDBOX/.claude/dewey"
HOME="$MAIN_CH_SANDBOX" \
DEWEY_DIR="$MAIN_CH_DEWEY" \
DEWEY_REPO="https://example.invalid/dewey" \
DEWEY_REF="main" \
DEWEY_TARBALL="file://$TARBALL_FILE" \
bash "$REPO_ROOT/install.sh" >/dev/null 2>&1

MAIN_CH_REFRESH="$MAIN_CH_SANDBOX/.claude/dewey-refresh.sh"
check "refresh.sh (main channel) succeeds without checksum" \
  "HOME='$MAIN_CH_SANDBOX' \
   DEWEY_DIR='$MAIN_CH_DEWEY' \
   DEWEY_REFRESH_INTERVAL=0 \
   DEWEY_REFRESH_CHANNEL=main \
   DEWEY_TARBALL='file://$TARBALL_FILE' \
   bash '$MAIN_CH_REFRESH'"

check "refresh.sh (main channel) preserved guide/SKILL.md" \
  "test -f '$MAIN_CH_DEWEY/guide/SKILL.md'"
