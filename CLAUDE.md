# Classroom — session notes

## Current state (2026-04-11)

Classroom is a Claude Code plugin marketplace convention. It ships 4 in-tree plugins and references 3 external templates from `ckoglmeier/skills/templates/` via `git-subdir` in `.claude-plugin/marketplace.json`.

All 127 tests pass. Both repos are pushed and green on `main`.

## What to pick up next

### 1. Verify external plugin install (manual, ~2 min)

Run in a live Claude Code session:

```
/plugin install research-assistant@classroom
```

This is the ground truth that the `git-subdir` source object resolves end-to-end. If it fails, the fix is in the `marketplace.json` source object shape — the install pipeline and test suite don't need changes.

Also try `exec-feedback@classroom` and `template-strategy-feedback@classroom` for coverage.

### 2. Layer 8 — opt-in live validation (deferred)

Add an opt-in test layer gated by `CLASSROOM_VALIDATE_EXTERNAL=1` to `tests/run.sh`. For each object-source entry:
- `git ls-remote` the URL to confirm repo is reachable and ref resolves
- Sparse-clone, then assert `plugin.json` exists at the target path and its `name` field matches the marketplace entry

Plan file with full details: `/Users/ck/.claude/plans/external-template-sources.md` (see "Follow-ups" section).

### 3. Weekly drift-check GitHub Action (deferred)

Natural home for Layer 8 once it exists: cron runs it against `main`, files an issue on drift between classroom's marketplace entries and the upstream skill content.

### 4. SHA pinning + bump workflow (deferred, only if needed)

Currently external entries use `"ref": "main"`. If upstream breakage becomes a real problem, move to SHA pinning with a bump script or Action that opens PRs when upstream templates update. No evidence yet that this is needed — 24h refresh cadence bounds the blast radius.

## Key decisions made this session

- **External references over in-tree copies.** Templates live in `ckoglmeier/skills/templates/`, classroom points at them. Avoids drift, keeps classroom thin.
- **`family-assistant` is personal.** Moved to `playbooks/` in the skills repo. Not referenced from classroom.
- **`ref: main` pinning.** Accepted the simplicity-over-determinism tradeoff for now.
- **Layer 3b ships now, Layer 8 deferred.** Offline schema validation is in the test suite; live sparse-clone validation comes later once we see rough edges.
- **Original 4 plugins stay in-tree.** They're authored for classroom's audience. The skills repo is CK's personal library — different purpose, different audience.

## Repo topology

- `ckoglmeier/classroom` — this repo. Marketplace manifest, guide skill, in-tree plugins, install pipeline, tests.
- `ckoglmeier/skills` — CK's personal skill library. `templates/` (shareable, referenced from here), `playbooks/` (personal), `borrowed/` (third-party mirrors).
