# ============================================================================
# LAYER 6: TARBALL INSTALL PATH (no git, atomic swap, checksum, guard)
# ============================================================================
section "Layer 6 — Tarball install path"

# Build a local tarball that mimics the GitHub /archive/<ref>.tar.gz layout
# (single top-level dir; we use --strip-components=1 to remove it on extract).
TARBALL_DIR="$(mktemp -d)"
TMPDIRS_TO_CLEAN=("$SANDBOX" "$TARBALL_DIR")
cleanup_tmpdirs() {
  for d in "${TMPDIRS_TO_CLEAN[@]}"; do
    [ -n "$d" ] && [ -d "$d" ] && rm -rf "$d"
  done
}
trap cleanup_tmpdirs EXIT

# Stage repo contents under a single parent dir, excluding tests/ (avoid recursion)
# and .git/. We then tar that single parent so --strip-components=1 cleanly removes it.
mkdir -p "$TARBALL_DIR/stage/dewey-snapshot"
if command -v rsync >/dev/null 2>&1; then
  rsync -a --exclude='tests/' --exclude='.git/' "$REPO_ROOT/" "$TARBALL_DIR/stage/dewey-snapshot/" 2>/dev/null
else
  cp -R "$REPO_ROOT/." "$TARBALL_DIR/stage/dewey-snapshot/"
  rm -rf "$TARBALL_DIR/stage/dewey-snapshot/tests" "$TARBALL_DIR/stage/dewey-snapshot/.git"
fi

TARBALL_FILE="$TARBALL_DIR/dewey.tar.gz"
( cd "$TARBALL_DIR/stage" && tar -czf "$TARBALL_FILE" dewey-snapshot )

check "test tarball was built" \
  "test -s '$TARBALL_FILE'"

if command -v sha256sum >/dev/null 2>&1; then
  TARBALL_SHA=$(sha256sum "$TARBALL_FILE" | awk '{print $1}')
else
  TARBALL_SHA=$(shasum -a 256 "$TARBALL_FILE" | awk '{print $1}')
fi

# Fresh sandbox with NO pre-populated DEWEY_DIR — install must download.
TARBALL_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$TARBALL_SANDBOX")
TARBALL_SANDBOX_DEWEY="$TARBALL_SANDBOX/.claude/dewey"

run_tarball_install() {
  HOME="$TARBALL_SANDBOX" \
  DEWEY_DIR="$TARBALL_SANDBOX_DEWEY" \
  DEWEY_REPO="https://example.invalid/dewey" \
  DEWEY_REF="main" \
  DEWEY_TARBALL="file://$TARBALL_FILE" \
  bash "$REPO_ROOT/install.sh" >"$TARBALL_SANDBOX/install.log" 2>&1
}

check "install.sh runs cleanly via tarball (no git)" \
  "run_tarball_install"

check "tarball install populated guide/SKILL.md" \
  "test -f '$TARBALL_SANDBOX_DEWEY/guide/SKILL.md'"

check "tarball install populated marketplace.json" \
  "test -f '$TARBALL_SANDBOX_DEWEY/.claude-plugin/marketplace.json'"

check "tarball install installed Guide as personal skill" \
  "test -f '$TARBALL_SANDBOX/.claude/skills/dewey/SKILL.md'"

check "tarball install left no .old or .new sibling dirs" \
  "test ! -e '$TARBALL_SANDBOX_DEWEY.new' && ! ls -d '$TARBALL_SANDBOX_DEWEY'.old.* >/dev/null 2>&1"

check "tarball install registered the marketplace in known_marketplaces.json" \
  "python3 -c '
import json
s = json.load(open(\"$TARBALL_SANDBOX/.claude/plugins/known_marketplaces.json\"))
assert \"dewey\" in s
assert s[\"dewey\"][\"source\"][\"source\"] == \"directory\"
'"

check "tarball install dropped a refresh script" \
  "test -x '$TARBALL_SANDBOX/.claude/dewey-refresh.sh'"

# Idempotent re-run via tarball
check "tarball install is idempotent" \
  "run_tarball_install"

check "second tarball run still left no stale .old.* dirs" \
  "test ! -e '$TARBALL_SANDBOX_DEWEY.new' && ! ls -d '$TARBALL_SANDBOX_DEWEY'.old.* >/dev/null 2>&1"

# ---- Checksum verification --------------------------------------------------

# Pass: correct SHA
TARBALL_SANDBOX_OK="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$TARBALL_SANDBOX_OK")
check "tarball install passes with matching DEWEY_TARBALL_SHA256" \
  "HOME='$TARBALL_SANDBOX_OK' DEWEY_DIR='$TARBALL_SANDBOX_OK/.claude/dewey' DEWEY_TARBALL='file://$TARBALL_FILE' DEWEY_TARBALL_SHA256='$TARBALL_SHA' bash '$REPO_ROOT/install.sh' >/dev/null 2>&1"

# Fail: wrong SHA, must abort and leave DEWEY_DIR untouched
TARBALL_SANDBOX_BAD="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$TARBALL_SANDBOX_BAD")
check "tarball install aborts on bad DEWEY_TARBALL_SHA256" \
  "HOME='$TARBALL_SANDBOX_BAD' DEWEY_DIR='$TARBALL_SANDBOX_BAD/.claude/dewey' DEWEY_TARBALL='file://$TARBALL_FILE' DEWEY_TARBALL_SHA256='0000000000000000000000000000000000000000000000000000000000000000' bash '$REPO_ROOT/install.sh' >/dev/null 2>&1; test \$? -ne 0"

check "bad-checksum run did NOT populate DEWEY_DIR" \
  "test ! -f '$TARBALL_SANDBOX_BAD/.claude/dewey/guide/SKILL.md'"

# ---- Destructive-path guard -------------------------------------------------

# DEWEY_DIR that doesn't end in .claude/dewey must be refused.
GUARD_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$GUARD_SANDBOX")
mkdir -p "$GUARD_SANDBOX/somewhere-else"
echo "do not delete me" > "$GUARD_SANDBOX/somewhere-else/canary.txt"
check "install.sh refuses DEWEY_DIR that doesn't end in .claude/dewey" \
  "HOME='$GUARD_SANDBOX' DEWEY_DIR='$GUARD_SANDBOX/somewhere-else' DEWEY_TARBALL='file://$TARBALL_FILE' bash '$REPO_ROOT/install.sh' >/dev/null 2>&1; test \$? -ne 0"

check "guard left the canary file untouched" \
  "test -f '$GUARD_SANDBOX/somewhere-else/canary.txt'"

# ---- No git on PATH ---------------------------------------------------------

# Build a stripped PATH dir that excludes git but includes essentials.
STRIP_DIR="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$STRIP_DIR")
# gzip is required on Linux: GNU tar execs it from PATH for -z, while
# macOS bsdtar decompresses internally (which is why its absence only
# shows up in CI). sha256sum/env/ln etc. round out the GNU userland.
for tool in bash sh curl tar shasum sha256sum gzip gunzip python3 mktemp dirname rm mv mkdir cp ls cat date stat awk sed grep printf chmod cmp basename head touch find file env ln uname readlink sleep tr cut wc sort id tee; do
  src="$(command -v "$tool" 2>/dev/null || true)"
  if [ -n "$src" ]; then
    ln -sf "$src" "$STRIP_DIR/$tool" 2>/dev/null || true
  fi
done
NOGIT_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$NOGIT_SANDBOX")
check "install.sh runs with git absent from PATH" \
  "PATH='$STRIP_DIR' HOME='$NOGIT_SANDBOX' DEWEY_DIR='$NOGIT_SANDBOX/.claude/dewey' DEWEY_TARBALL='file://$TARBALL_FILE' bash '$REPO_ROOT/install.sh' >/dev/null 2>&1"

check "no-git install populated guide/SKILL.md" \
  "test -f '$NOGIT_SANDBOX/.claude/dewey/guide/SKILL.md'"

# ---- Release resolution — unit tests (no network) ----------------------------
# These tests exercise resolve_release() and the parse_release.py helper
# against canned API JSON fixtures. No network is used.

FIXTURE_DIR="$REPO_ROOT/tests/fixtures/release-api"
PARSE_PY="$FIXTURE_DIR/parse_release.py"
RUN_RESOLVE="$FIXTURE_DIR/run_resolve.sh"

# Create the companion .sha256 file that resolve_release() looks for in test mode.
# Use the real checksum of our test tarball so a later end-to-end test can verify it.
echo "$TARBALL_SHA  dewey-v99.0.0.tar.gz" > "$FIXTURE_DIR/dewey-v99.0.0.tar.gz.sha256"

check "parse_release.py extracts tag from fixture" \
  "out=\$(python3 '$PARSE_PY' '$FIXTURE_DIR/release-latest.json'); echo \"\$out\" | grep -q 'tag=v99.0.0'"

check "parse_release.py extracts asset_url from fixture" \
  "out=\$(python3 '$PARSE_PY' '$FIXTURE_DIR/release-latest.json'); echo \"\$out\" | grep -q 'asset_url=https://example.invalid/dewey-v99.0.0.tar.gz'"

check "parse_release.py extracts sha256_url from fixture" \
  "out=\$(python3 '$PARSE_PY' '$FIXTURE_DIR/release-latest.json'); echo \"\$out\" | grep -q 'sha256_url=https://example.invalid/dewey-v99.0.0.tar.gz.sha256'"

check "parse_release.py returns empty asset_url when no assets" \
  "out=\$(python3 '$PARSE_PY' '$FIXTURE_DIR/release-no-assets.json'); echo \"\$out\" | grep -q 'asset_url='"

check "run_resolve.sh sets DEWEY_REF from fixture" \
  "out=\$(bash '$RUN_RESOLVE' '$REPO_ROOT/install.sh' '$FIXTURE_DIR/release-latest.json' 2>/dev/null); echo \"\$out\" | grep -q 'DEWEY_REF=v99.0.0'"

check "run_resolve.sh sets _DEWEY_RELEASE_ASSET_URL from fixture" \
  "out=\$(bash '$RUN_RESOLVE' '$REPO_ROOT/install.sh' '$FIXTURE_DIR/release-latest.json' 2>/dev/null); echo \"\$out\" | grep -q '_DEWEY_RELEASE_ASSET_URL=https://example.invalid/dewey-v99.0.0.tar.gz'"

check "run_resolve.sh sets _DEWEY_RELEASE_SHA256 from sibling .sha256 file" \
  "out=\$(bash '$RUN_RESOLVE' '$REPO_ROOT/install.sh' '$FIXTURE_DIR/release-latest.json' 2>/dev/null); echo \"\$out\" | grep -q '_DEWEY_RELEASE_SHA256=$TARBALL_SHA'"

check "run_resolve.sh leaves asset URL empty when no assets in fixture" \
  "out=\$(bash '$RUN_RESOLVE' '$REPO_ROOT/install.sh' '$FIXTURE_DIR/release-no-assets.json' 2>/dev/null); echo \"\$out\" | grep -q '_DEWEY_RELEASE_ASSET_URL=\$'"

check "run_resolve.sh falls back to main when fixture has empty JSON" \
  "empty_fix=\$(mktemp); echo '{}' > \"\$empty_fix\"; out=\$(bash '$RUN_RESOLVE' '$REPO_ROOT/install.sh' \"\$empty_fix\" 2>/dev/null); echo \"\$out\" | grep -q 'DEWEY_REF=main'; rm -f \"\$empty_fix\""

# ---- Checksum-required failure: release-asset install with wrong .sha256 -----
# When DEWEY_TARBALL and DEWEY_TARBALL_SHA256 are both set and the hash is wrong,
# install must abort with a non-zero exit and leave DEWEY_DIR empty.
BADSHA_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$BADSHA_SANDBOX")
check "release-asset install with wrong SHA-256 must abort" \
  "HOME='$BADSHA_SANDBOX' \
   DEWEY_DIR='$BADSHA_SANDBOX/.claude/dewey' \
   DEWEY_TARBALL='file://$TARBALL_FILE' \
   DEWEY_TARBALL_SHA256='0000000000000000000000000000000000000000000000000000000000000000' \
   bash '$REPO_ROOT/install.sh' >/dev/null 2>&1; test \$? -ne 0"

check "release-asset abort left DEWEY_DIR empty" \
  "test ! -f '$BADSHA_SANDBOX/.claude/dewey/guide/SKILL.md'"
