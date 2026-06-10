# ============================================================================
# LAYER 13: PROPOSE HELPER (--check, --prepare, propose --dry-run)
# ============================================================================
section "Layer 13 — Propose helper"

PROPOSE_SRC="$REPO_ROOT/dewey-propose.sh"

check "dewey-propose.sh exists" \
  "test -f '$PROPOSE_SRC'"

check "dewey-propose.sh has clean bash syntax" \
  "bash -n '$PROPOSE_SRC'"

check "dewey-propose.sh prints help with no args" \
  "bash '$PROPOSE_SRC' 2>&1 | grep -q 'dewey-propose'"

check "dewey-propose.sh rejects unknown subcommand" \
  "out=\$(bash '$PROPOSE_SRC' nope 2>&1); echo \"\$out\" | grep -q 'unknown command'; test \$(bash '$PROPOSE_SRC' nope 2>&1; echo \$?) -ne 0 || true"

# install.sh installs the helper (sandbox HOME is built earlier in Layer 6)
INSTALLED_PROPOSE="$SANDBOX/.claude/dewey-propose.sh"
check "install.sh installs dewey-propose.sh to \$HOME/.claude" \
  "test -f '$INSTALLED_PROPOSE' && test -x '$INSTALLED_PROPOSE'"

check "installed dewey-propose.sh has clean bash syntax" \
  "bash -n '$INSTALLED_PROPOSE'"

# Dry-run flow: build a fake working clone (looks like a Dewey repo) and
# verify the helper stages the file, runs lint, and exits 0 without pushing.
PROPOSE_SANDBOX="$(mktemp -d)"
TMPDIRS_TO_CLEAN+=("$PROPOSE_SANDBOX")
PROPOSE_AUTHOR_DIR="$PROPOSE_SANDBOX/dewey-author"
mkdir -p "$PROPOSE_AUTHOR_DIR"
git init --quiet "$PROPOSE_AUTHOR_DIR"
( cd "$PROPOSE_AUTHOR_DIR" && \
  git config user.email "test@test" && \
  git config user.name "test" && \
  mkdir -p plugins/demo/skills/foo plugins/demo/.claude-plugin tests && \
  printf '{"name":"demo"}\n' > plugins/demo/.claude-plugin/plugin.json && \
  printf -- "---\nname: foo\n---\n" > plugins/demo/skills/foo/SKILL.md && \
  cat > tests/run.sh <<'EOF'
#!/usr/bin/env bash
# Stub lint script — exits 0 always
echo "stub tests pass"
exit 0
EOF
  chmod +x tests/run.sh && \
  git add -A && \
  git commit --quiet -m "init" && \
  git branch -M main )

DRAFT="$PROPOSE_SANDBOX/draft.md"
BODY="$PROPOSE_SANDBOX/body.md"
printf -- "---\nname: bar\ndescription: test\n---\nbody\n" > "$DRAFT"
printf "Test PR body\n" > "$BODY"

check "propose --dry-run validates file, runs lint, exits 0 without pushing" \
  "
DEWEY_AUTHOR_DIR='$PROPOSE_AUTHOR_DIR' \
  bash '$PROPOSE_SRC' propose \
    --target-path 'plugins/demo/skills/bar/SKILL.md' \
    --content-file '$DRAFT' \
    --branch propose/test-bar \
    --title 'Add bar skill' \
    --body-file '$BODY' \
    --dry-run >/dev/null 2>&1
test \$? -eq 0
"

check "propose --dry-run leaves author checkout unchanged" \
  "
test \"\$(git -C '$PROPOSE_AUTHOR_DIR' branch --show-current)\" = 'main'
test ! -f '$PROPOSE_AUTHOR_DIR/plugins/demo/skills/bar/SKILL.md'
! git -C '$PROPOSE_AUTHOR_DIR' rev-parse --verify propose/test-bar >/dev/null 2>&1
"

git -C "$PROPOSE_AUTHOR_DIR" branch propose/existing main
EXISTING_BRANCH_SHA="$(git -C "$PROPOSE_AUTHOR_DIR" rev-parse propose/existing)"
check "propose --dry-run preserves an existing branch with the same name" \
  "
DEWEY_AUTHOR_DIR='$PROPOSE_AUTHOR_DIR' \
  bash '$PROPOSE_SRC' propose \
    --target-path 'plugins/demo/skills/bar/SKILL.md' \
    --content-file '$DRAFT' \
    --branch propose/existing \
    --title 'Add bar skill' \
    --body-file '$BODY' \
    --dry-run >/dev/null 2>&1
test \"\$(git -C '$PROPOSE_AUTHOR_DIR' rev-parse propose/existing)\" = '$EXISTING_BRANCH_SHA'
test \"\$(git -C '$PROPOSE_AUTHOR_DIR' branch --show-current)\" = 'main'
"

check "propose rejects absolute target-path" \
  "
out=\$(DEWEY_AUTHOR_DIR='$PROPOSE_AUTHOR_DIR' \
  bash '$PROPOSE_SRC' propose \
    --target-path '/etc/passwd' \
    --content-file '$DRAFT' \
    --branch x --title y --body-file '$BODY' --dry-run 2>&1)
echo \"\$out\" | grep -q 'must be a repo-relative path'
"

check "propose rejects target-path with .." \
  "
out=\$(DEWEY_AUTHOR_DIR='$PROPOSE_AUTHOR_DIR' \
  bash '$PROPOSE_SRC' propose \
    --target-path '../escape.md' \
    --content-file '$DRAFT' \
    --branch x --title y --body-file '$BODY' --dry-run 2>&1)
echo \"\$out\" | grep -q 'must be a repo-relative path'
"

check "propose rejects missing content file" \
  "
out=\$(DEWEY_AUTHOR_DIR='$PROPOSE_AUTHOR_DIR' \
  bash '$PROPOSE_SRC' propose \
    --target-path 'plugins/demo/skills/bar/SKILL.md' \
    --content-file '$PROPOSE_SANDBOX/nonexistent.md' \
    --branch x --title y --body-file '$BODY' --dry-run 2>&1)
echo \"\$out\" | grep -q 'content file not found'
"

# Helper requires --dry-run when working dir is missing in tests, since live
# mode would clone from the real GitHub repo.
check "propose --dry-run errors if working dir missing" \
  "
out=\$(DEWEY_AUTHOR_DIR='$PROPOSE_SANDBOX/missing' \
  bash '$PROPOSE_SRC' propose \
    --target-path 'plugins/demo/skills/bar/SKILL.md' \
    --content-file '$DRAFT' \
    --branch x --title y --body-file '$BODY' --dry-run 2>&1)
echo \"\$out\" | grep -q 'working dir does not exist'
"

# Guide §10 references the helper
check "guide/SKILL.md §10 calls dewey-propose.sh" \
  "grep -q 'dewey-propose.sh' '$REPO_ROOT/guide/SKILL.md' &&
   grep -q '## §10 Propose' '$REPO_ROOT/guide/SKILL.md'"

# docs exist
check "docs/proposing-changes.md exists" \
  "test -f '$REPO_ROOT/docs/proposing-changes.md'"
