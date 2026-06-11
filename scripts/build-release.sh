#!/usr/bin/env bash
# scripts/build-release.sh
#
# Build a release tarball and SHA-256 checksum file for the current HEAD.
# Output goes to dist/dewey-<tag>.tar.gz and dist/dewey-<tag>.tar.gz.sha256.
# The tag must already exist in the local repo.
#
# Usage:
#   bash scripts/build-release.sh <tag>
#   bash scripts/build-release.sh          # uses the most recent git tag
#
# After running, the script prints the `gh release create` command to execute.
# This script does NOT push, tag, or create releases itself.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

say()  { printf "\n\033[1;36m▸\033[0m %s\n" "$*"; }
warn() { printf "\n\033[1;33m!\033[0m %s\n" "$*"; }
die()  { printf "\n\033[1;31m✗\033[0m %s\n" "$*" >&2; exit 1; }

# ---- Resolve tag ------------------------------------------------------------
if [ "${1:-}" != "" ]; then
  TAG="$1"
else
  TAG="$(git -C "$REPO_ROOT" describe --tags --abbrev=0 2>/dev/null)" || \
    die "No tag supplied and no git tags found. Run: git tag vX.Y.Z first."
fi

# Validate the tag looks like a version.
case "$TAG" in
  v[0-9]*) : ;;
  *) warn "Tag '$TAG' does not start with 'v'. Continuing anyway." ;;
esac

# Confirm the tag exists as a git ref.
git -C "$REPO_ROOT" rev-parse --verify "refs/tags/$TAG" >/dev/null 2>&1 || \
  die "Tag '$TAG' not found in this repo. Create it first: git tag $TAG"

# ---- Build tarball ----------------------------------------------------------
DIST_DIR="$REPO_ROOT/dist"
mkdir -p "$DIST_DIR"

TARBALL_NAME="dewey-${TAG}.tar.gz"
SHA256_NAME="dewey-${TAG}.tar.gz.sha256"
TARBALL_PATH="$DIST_DIR/$TARBALL_NAME"
SHA256_PATH="$DIST_DIR/$SHA256_NAME"

say "Building $TARBALL_NAME from tag $TAG"

# git archive produces a clean tarball from the tagged commit, with a single
# top-level directory named dewey-<tag>/ — matching what GitHub's own
# /archive/<tag>.tar.gz produces for install.sh's --strip-components=1.
git -C "$REPO_ROOT" archive \
  --format=tar.gz \
  --prefix="dewey-${TAG}/" \
  --output="$TARBALL_PATH" \
  "$TAG"

# ---- Generate checksum ------------------------------------------------------
say "Writing $SHA256_NAME"
if command -v sha256sum >/dev/null 2>&1; then
  (cd "$DIST_DIR" && sha256sum "$TARBALL_NAME" > "$SHA256_NAME")
elif command -v shasum >/dev/null 2>&1; then
  (cd "$DIST_DIR" && shasum -a 256 "$TARBALL_NAME" > "$SHA256_NAME")
else
  die "Neither sha256sum nor shasum found. Install one and retry."
fi

# ---- Report -----------------------------------------------------------------
CHECKSUM="$(awk '{print $1}' "$SHA256_PATH")"
TARBALL_SIZE="$(wc -c < "$TARBALL_PATH" | tr -d ' ')"

echo
echo "  Tarball : $TARBALL_PATH"
echo "  Size    : $TARBALL_SIZE bytes"
echo "  SHA-256 : $CHECKSUM"
echo

say "Next step — create the GitHub release:"
echo
echo "  gh release create $TAG \\"
echo "    '$TARBALL_PATH' \\"
echo "    '$SHA256_PATH' \\"
echo "    --generate-notes"
echo
echo "Verify the release install works before announcing:"
echo
echo "  curl -fsSL https://raw.githubusercontent.com/ckoglmeier/dewey/main/install.sh | bash"
echo
