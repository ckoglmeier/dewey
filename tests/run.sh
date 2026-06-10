#!/usr/bin/env bash
# Dewey test suite
#
# Thin harness: defines the shared test framework, then sources each layer
# from tests/layers/ in order. Layers share state (counters, sandboxes,
# helper functions) — order matters, do not reorder or parallelize.
#
# Usage:  bash tests/run.sh
# Exit:   0 if all tests pass, 1 if any failed.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# ---- Test framework ---------------------------------------------------------
PASSED=0
FAILED=0
FAILED_NAMES=()

red()    { printf "\033[1;31m%s\033[0m" "$*"; }
green()  { printf "\033[1;32m%s\033[0m" "$*"; }
yellow() { printf "\033[1;33m%s\033[0m" "$*"; }
bold()   { printf "\033[1m%s\033[0m" "$*"; }

pass() {
  PASSED=$((PASSED + 1))
  printf "  %s %s\n" "$(green ✓)" "$1"
}

fail() {
  FAILED=$((FAILED + 1))
  FAILED_NAMES+=("$1")
  printf "  %s %s\n" "$(red ✗)" "$1"
  if [ -n "${2:-}" ]; then
    printf "      %s\n" "$2"
  fi
}

section() {
  printf "\n%s\n" "$(bold "$1")"
}

# Run a check: $1 = name, $2 = command (eval'd). Pass if exit 0.
check() {
  local name="$1"
  local cmd="$2"
  local out
  if out=$(eval "$cmd" 2>&1); then
    pass "$name"
  else
    fail "$name" "${out:-(no output)}"
  fi
}

# ============================================================================
# SOURCE EACH LAYER IN ORDER
# ============================================================================
# A missing or unreadable layer file must abort loudly — otherwise the suite
# would skip a whole layer and still report green.

LAYERS=(
  layer-01-static.sh
  layer-02-frontmatter.sh
  layer-03-crossref.sh
  layer-04-install.sh
  layer-04b-migration.sh
  layer-05-ownership.sh
  layer-06-tarball.sh
  layer-07-refresh.sh
  layer-08-external-live.sh
  layer-09-analytics.sh
  layer-10-codex-sync.sh
  layer-11-surfaces.sh
  layer-12-telemetry.sh
  layer-13-propose.sh
  layer-14-context.sh
  layer-15-triggers.sh
  layer-16-hosted.sh
)

for layer in "${LAYERS[@]}"; do
  layer_path="$REPO_ROOT/tests/layers/$layer"
  if [ ! -f "$layer_path" ]; then
    printf "%s missing layer file: %s\n" "$(red FATAL:)" "$layer_path" >&2
    exit 2
  fi
  source "$layer_path"
done

# ============================================================================
# RESULTS
# ============================================================================
TOTAL=$((PASSED + FAILED))
printf "\n%s\n" "$(bold "Results:")"
printf "  Total:  %d\n" "$TOTAL"
printf "  %s: %d\n" "$(green Passed)" "$PASSED"
printf "  %s: %d\n" "$(red Failed)" "$FAILED"

if [ "$FAILED" -gt 0 ]; then
  printf "\n%s\n" "$(red "Failed tests:")"
  for n in "${FAILED_NAMES[@]}"; do
    printf "  - %s\n" "$n"
  done
  exit 1
fi

printf "\n%s\n" "$(green "All tests passed.")"
exit 0
