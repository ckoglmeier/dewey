#!/usr/bin/env bash
# Classroom propose helper — turn a drafted change into a GitHub PR.
#
# Usage:
#   classroom-propose.sh --check
#       Verify prerequisites (gh installed, gh authenticated, repo reachable).
#       Exit 0 if ready, non-zero with a clear message otherwise.
#
#   classroom-propose.sh --prepare
#       Clone the Classroom repo to the working dir if missing, or fetch+reset
#       to origin/main if present. No-op if nothing changed.
#
#   classroom-propose.sh propose \
#       --target-path PATH \
#       --content-file FILE \
#       --branch BRANCH \
#       --title TITLE \
#       --body-file FILE \
#       [--dry-run]
#
#       Stage CONTENT_FILE at TARGET_PATH (relative to repo root) on a new
#       branch off origin/main, run tests/run.sh, commit, push, open a PR via
#       gh. Auto-forks if the user lacks write access. Prints PR URL on success.
#
# Env:
#   CLASSROOM_REPO            Source repo URL (default https://github.com/ckoglmeier/classroom)
#   CLASSROOM_AUTHOR_DIR      Working clone (default ~/.claude/classroom-author)

set -euo pipefail

CLASSROOM_REPO="${CLASSROOM_REPO:-https://github.com/ckoglmeier/classroom}"
CLASSROOM_AUTHOR_DIR="${CLASSROOM_AUTHOR_DIR:-$HOME/.claude/classroom-author}"

green()  { printf "\033[1;32m%s\033[0m" "$*"; }
yellow() { printf "\033[1;33m%s\033[0m" "$*"; }
red()    { printf "\033[1;31m%s\033[0m" "$*"; }
say()    { printf "\033[1;36m▸\033[0m %s\n" "$*"; }
note()   { printf "  %s\n" "$*"; }
err()    { printf "$(red Error:) %s\n" "$*" >&2; }

# ---- Prerequisite check ---------------------------------------------------
do_check() {
  local fail=0
  if ! command -v gh >/dev/null 2>&1; then
    err "gh CLI not installed. Install: https://cli.github.com/"
    fail=1
  else
    note "gh CLI: $(gh --version | head -1)"
  fi
  if command -v gh >/dev/null 2>&1; then
    if ! gh auth status >/dev/null 2>&1; then
      err "gh is not authenticated. Run: gh auth login"
      fail=1
    else
      note "gh authenticated"
    fi
  fi
  if ! command -v git >/dev/null 2>&1; then
    err "git not installed."
    fail=1
  fi
  return $fail
}

# ---- Working dir setup ----------------------------------------------------
do_prepare() {
  if [[ ! -d "$CLASSROOM_AUTHOR_DIR/.git" ]]; then
    say "Cloning $CLASSROOM_REPO to $CLASSROOM_AUTHOR_DIR"
    mkdir -p "$(dirname "$CLASSROOM_AUTHOR_DIR")"
    git clone --quiet "$CLASSROOM_REPO" "$CLASSROOM_AUTHOR_DIR"
  else
    say "Refreshing $CLASSROOM_AUTHOR_DIR from origin/main"
    git -C "$CLASSROOM_AUTHOR_DIR" fetch --quiet origin
    # Discard any local edits from a prior aborted run; we always start clean.
    git -C "$CLASSROOM_AUTHOR_DIR" checkout --quiet main 2>/dev/null \
      || git -C "$CLASSROOM_AUTHOR_DIR" checkout --quiet -b main origin/main
    git -C "$CLASSROOM_AUTHOR_DIR" reset --hard --quiet origin/main
    git -C "$CLASSROOM_AUTHOR_DIR" clean -fdq
  fi
}

# ---- Detect write access vs fork mode -------------------------------------
detect_mode() {
  # Returns: "write" if user can push to origin, "fork" otherwise.
  # Uses gh api to check repo permissions.
  local owner_repo
  owner_repo=$(echo "$CLASSROOM_REPO" | sed -E 's#.*github\.com[:/]##; s#\.git$##')
  local perm
  perm=$(gh api "repos/$owner_repo" --jq '.permissions.push' 2>/dev/null || echo "false")
  if [[ "$perm" == "true" ]]; then
    echo "write"
  else
    echo "fork"
  fi
}

# ---- Propose a change -----------------------------------------------------
do_propose() {
  local target_path="" content_file="" branch="" title="" body_file="" dry_run=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --target-path)  target_path="$2"; shift 2 ;;
      --content-file) content_file="$2"; shift 2 ;;
      --branch)       branch="$2"; shift 2 ;;
      --title)        title="$2"; shift 2 ;;
      --body-file)    body_file="$2"; shift 2 ;;
      --dry-run)      dry_run=1; shift ;;
      *) err "unknown flag: $1"; return 1 ;;
    esac
  done

  for required in target_path content_file branch title body_file; do
    if [[ -z "${!required}" ]]; then
      err "missing required flag: --${required//_/-}"
      return 1
    fi
  done

  if [[ ! -f "$content_file" ]]; then
    err "content file not found: $content_file"
    return 1
  fi
  if [[ ! -f "$body_file" ]]; then
    err "body file not found: $body_file"
    return 1
  fi
  if [[ "$target_path" == /* || "$target_path" == *..* ]]; then
    err "target-path must be a repo-relative path, not absolute or containing '..'"
    return 1
  fi

  # In dry-run we skip the network bits but still validate inputs and lint.
  if [[ $dry_run -eq 0 ]]; then
    do_check >/dev/null || { err "prerequisites failed; run --check for details"; return 1; }
    do_prepare
  else
    say "[dry-run] would prepare working dir at $CLASSROOM_AUTHOR_DIR"
    if [[ ! -d "$CLASSROOM_AUTHOR_DIR/.git" ]]; then
      err "[dry-run] working dir does not exist; run with --prepare first or run live"
      return 1
    fi
  fi

  local repo_dir="$CLASSROOM_AUTHOR_DIR"
  local tmp_parent worktree_dir base_ref
  tmp_parent="$(mktemp -d)"
  worktree_dir="$tmp_parent/worktree"

  if git -C "$repo_dir" rev-parse --verify origin/main >/dev/null 2>&1; then
    base_ref="origin/main"
  elif git -C "$repo_dir" rev-parse --verify main >/dev/null 2>&1; then
    base_ref="main"
  else
    base_ref="HEAD"
  fi

  cleanup_worktree() {
    if [[ -n "${worktree_dir:-}" && -d "$worktree_dir/.git" ]]; then
      git -C "$repo_dir" worktree remove --force "$worktree_dir" >/dev/null 2>&1 || true
    fi
    if [[ -n "${tmp_parent:-}" && -d "$tmp_parent" ]]; then
      rm -rf "$tmp_parent"
    fi
  }

  say "Preparing temporary worktree from $base_ref"
  if ! git -C "$repo_dir" worktree add --quiet --detach "$worktree_dir" "$base_ref"; then
    cleanup_worktree
    err "failed to create temporary worktree"
    return 1
  fi

  if [[ $dry_run -eq 0 ]]; then
    say "Branching: $branch"
    if ! git -C "$worktree_dir" checkout --quiet -B "$branch"; then
      cleanup_worktree
      err "failed to create branch: $branch"
      return 1
    fi
  else
    say "[dry-run] validating change in a temporary worktree"
  fi

  local dest="$worktree_dir/$target_path"
  mkdir -p "$(dirname "$dest")"
  cp "$content_file" "$dest"
  note "Staged content at $target_path"

  if [[ -x "$worktree_dir/tests/run.sh" ]]; then
    say "Running tests/run.sh against the working tree"
    if ! ( cd "$worktree_dir" && bash tests/run.sh ) >/tmp/classroom-propose-test.log 2>&1; then
      err "tests/run.sh failed. Output:"
      tail -30 /tmp/classroom-propose-test.log >&2
      cleanup_worktree
      return 1
    fi
    note "tests passed"
  else
    note "no tests/run.sh in working tree — skipping lint"
  fi

  if [[ $dry_run -eq 1 ]]; then
    say "[dry-run] would push branch '$branch' and open a PR"
    note "Diff:"
    git -C "$worktree_dir" diff -- "$target_path" | sed 's/^/    /'
    note "Title: $title"
    note "Body:"
    sed 's/^/    /' "$body_file" >&2
    cleanup_worktree
    return 0
  fi

  if ! git -C "$worktree_dir" add -- "$target_path"; then
    cleanup_worktree
    err "failed to stage: $target_path"
    return 1
  fi
  if ! git -C "$worktree_dir" commit --quiet -m "$title"; then
    cleanup_worktree
    err "failed to commit change; content may be unchanged"
    return 1
  fi

  local mode
  mode=$(detect_mode)
  say "Push mode: $mode"

  if [[ "$mode" == "write" ]]; then
    if ! git -C "$worktree_dir" push --quiet -u origin "$branch"; then
      cleanup_worktree
      err "failed to push branch: $branch"
      return 1
    fi
    local pr_url
    if ! pr_url=$(cd "$worktree_dir" && gh pr create --title "$title" --body-file "$body_file" --base main --head "$branch"); then
      cleanup_worktree
      err "failed to open pull request"
      return 1
    fi
    say "$(green ✓) Pull request opened: $pr_url"
  else
    # Fork mode: fork the repo (idempotent), push to fork, open cross-repo PR.
    local owner_repo fork_owner
    owner_repo=$(echo "$CLASSROOM_REPO" | sed -E 's#.*github\.com[:/]##; s#\.git$##')
    say "User does not have write access; using fork-and-PR flow"
    if ! fork_owner=$(gh repo fork "$owner_repo" --remote --remote-name=fork --clone=false 2>&1 | sed -nE 's/.*Created fork ([^ ]+).*/\1/p'); then
      cleanup_worktree
      err "failed to create or inspect fork"
      return 1
    fi
    if [[ -z "$fork_owner" ]]; then
      # Already-forked path: detect existing fork
      if ! fork_owner="$(gh api user --jq .login)/$(basename "$owner_repo")"; then
        cleanup_worktree
        err "failed to detect fork owner"
        return 1
      fi
    fi
    if ! git -C "$worktree_dir" remote get-url fork >/dev/null 2>&1; then
      if ! git -C "$worktree_dir" remote add fork "https://github.com/$fork_owner.git"; then
        cleanup_worktree
        err "failed to add fork remote"
        return 1
      fi
    fi
    if ! git -C "$worktree_dir" push --quiet -u fork "$branch"; then
      cleanup_worktree
      err "failed to push branch to fork: $branch"
      return 1
    fi
    local pr_url
    if ! pr_url=$(cd "$worktree_dir" && gh pr create --title "$title" --body-file "$body_file" --base main --head "${fork_owner%%/*}:$branch" --repo "$owner_repo"); then
      cleanup_worktree
      err "failed to open pull request"
      return 1
    fi
    say "$(green ✓) Pull request opened: $pr_url"
  fi

  cleanup_worktree
}

# ---- Argument dispatch -----------------------------------------------------
case "${1:-}" in
  --check)    shift; do_check ;;
  --prepare)  shift; do_check >/dev/null && do_prepare ;;
  propose)    shift; do_propose "$@" ;;
  ""|-h|--help) sed -n '2,30p' "$0" ;;
  *) err "unknown command: $1"; sed -n '2,30p' "$0" >&2; exit 1 ;;
esac
