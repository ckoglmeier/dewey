#!/usr/bin/env bash
# run_resolve.sh <install_sh> <json_fixture> [<sha256_value_override>]
#
# Sources the resolve_release() function from install.sh in an isolated
# subshell and calls it with DEWEY_RESOLVE_RELEASE_JSON pointing at the
# supplied fixture. Prints the resolved values so tests can assert on them.
#
# Output:
#   DEWEY_REF=<tag>
#   _DEWEY_RELEASE_ASSET_URL=<url or empty>
#   _DEWEY_RELEASE_SHA256=<hash or empty>
#
# No network is used. The sha256 companion file is looked up in the same
# directory as the JSON fixture (same convention as resolve_release itself).

set -euo pipefail

INSTALL_SH="$1"
JSON_FIXTURE="$2"

# Extract only the function definitions we need from install.sh (up to the
# first non-comment, non-function-def executable statement).
# We source the whole file but skip the executable body by setting guard vars.
(
  # Set up the stubs install.sh needs to be sourceable without running.
  say()  { :; }
  warn() { printf "WARN: %s\n" "$*" >&2; }
  die()  { printf "DIE: %s\n" "$*" >&2; exit 1; }
  require() { :; }

  # Provide the configurable vars that resolve_release() reads.
  DEWEY_REPO="${DEWEY_REPO:-https://github.com/ckoglmeier/dewey}"
  DEWEY_REF=""
  DEWEY_TARBALL=""
  DEWEY_USE_INPLACE="0"
  _DEWEY_RELEASE_SHA256=""
  _DEWEY_RELEASE_ASSET_URL=""

  # Source only the function definitions. We do this by extracting the lines
  # between the first function definition and the "---- Preflight" marker.
  tmpf="$(mktemp)"
  python3 - "$INSTALL_SH" "$tmpf" <<'PY'
import sys, re

in_file = sys.argv[1]
out_file = sys.argv[2]

lines = open(in_file).readlines()

# Extract lines from start up to (but not including) the "---- Preflight" marker.
# This captures all function definitions at the top of the file.
out = []
for line in lines:
    if re.match(r'^#\s*----\s*Preflight', line):
        break
    out.append(line)

with open(out_file, 'w') as f:
    f.writelines(out)
PY

  # shellcheck disable=SC1090
  source "$tmpf"
  rm -f "$tmpf"

  DEWEY_RESOLVE_RELEASE_JSON="$JSON_FIXTURE"
  resolve_release

  printf "DEWEY_REF=%s\n" "$DEWEY_REF"
  printf "_DEWEY_RELEASE_ASSET_URL=%s\n" "$_DEWEY_RELEASE_ASSET_URL"
  printf "_DEWEY_RELEASE_SHA256=%s\n" "$_DEWEY_RELEASE_SHA256"
)
