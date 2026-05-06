# Proposing canonical changes

Most Classroom users only consume skills. A smaller group authors them — adds new ones, updates existing ones, promotes patterns from extensions back to canonical.

The `/classroom propose` flow exists to make this path conversational instead of "clone the repo, edit, PR." Non-engineer authors should not have to touch git directly.

## Three sub-flows

| Sub-flow | When to use it |
|---|---|
| `new-skill` | You have a fresh idea for a skill that doesn't exist yet |
| `update <skill>` | You want to change an existing canonical skill (improve instructions, fix a step, broaden trigger language) |
| `promote <extension>` | You wrote a local extension that's working well, and you want to either (a) merge its additions into the parent canonical or (b) split it out as a new canonical skill |

The `promote` flow is the loop closure: extensions are signal of what's missing from canonical, and `propose promote` is how that signal becomes a real PR.

## What happens behind the scenes

1. The Guide drafts the change conversationally and shows it to you.
2. You approve the draft.
3. The helper at `~/.claude/classroom-propose.sh` clones (or refreshes) a working copy of the canonical Classroom repo at `~/.claude/classroom-author/`.
4. It places the drafted content at the right path, runs `tests/run.sh` against the change, and commits to a feature branch.
5. It pushes the branch and opens a PR via the GitHub CLI (`gh`).
6. CODEOWNERS auto-tags the skill's owner; CI runs `tests/run.sh` again.
7. The owner reviews, approves, merges. Standard GitHub flow from there.

## Prerequisites

- `gh` CLI installed and authenticated (`gh auth status` should succeed).
- `git` installed.
- Network access to GitHub.

If you don't have direct write access to the canonical Classroom repo, the helper auto-forks and opens a cross-repo PR from your fork. You don't need to set anything up — `gh repo fork` handles it.

## Manual usage

```bash
# Verify prerequisites
bash ~/.claude/classroom-propose.sh --check

# Refresh the working clone without doing anything else
bash ~/.claude/classroom-propose.sh --prepare

# Stage a draft and open a PR (the Guide builds these args for you)
bash ~/.claude/classroom-propose.sh propose \
  --target-path plugins/competitive-intelligence/skills/competitive-deepdive/SKILL.md \
  --content-file /tmp/draft.md \
  --branch propose/new-skill-competitive-deepdive-20260506 \
  --title "Add \`competitive-deepdive\` to competitive-intelligence" \
  --body-file /tmp/body.md

# Dry-run — same flow but stops before pushing
bash ~/.claude/classroom-propose.sh propose ... --dry-run
```

The Guide handles all of this in `/classroom propose` — manual usage is mostly for debugging.

## What the PR body should contain

The Guide drafts this for you, but if you're writing it manually, include:

- **Summary**: one paragraph on what the change is and why.
- **Rationale**: especially for `promote`, cite the signal — "12 users have created similar extensions of this skill in the last 30 days" if you have access to the analytics.
- **What the user sees**: how the skill's behavior changes from the user's perspective.
- **Test plan**: usually "ran `bash tests/run.sh` locally; CI will re-run on PR."

## Approval

Approval happens on GitHub — there's no Classroom-specific gate. CODEOWNERS routes the PR to the right reviewer; once they approve and CI passes, anyone with merge rights can merge.

When Classroom moves to a hosted version, this layer gets richer — UI for non-technical authors, telemetry-informed reviewer hints, staged rollouts. For now, GitHub is the approval system.

## Related

- [extending-skills.md](extending-skills.md) — the extension convention `promote` is inverting
- [extension-telemetry.md](extension-telemetry.md) — the data that motivates `promote`
- [pr-checklist.md](pr-checklist.md) — what reviewers look for
