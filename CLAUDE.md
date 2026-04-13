# Classroom — session notes

## Current state (2026-04-12)

Classroom is a Claude Code plugin marketplace convention. It ships 4 in-tree plugins.

All 127 tests pass.

### Changes made this session (demo prep)

1. **`owner` → `author` in plugin.json.** Claude Code's plugin validator expects `"author"`, not `"owner"`. Fixed all 4 in-tree plugin.json files and matching Layer 5 tests.

2. **Removed 3 external `git-subdir` entries from marketplace.json.** Claude Code's `marketplace add` command validates the manifest and rejects `git-subdir` sources — even though the official marketplace (`claude-plugins-official`) uses them and they work at runtime. This is a Claude Code validator bug. The 3 external templates (exec-feedback, research-assistant, template-strategy-feedback) are still available via `@ck-skills`. Re-add once the validator supports `git-subdir`.

3. **Fixed install.sh marketplace registration.** The installer was writing to `extraKnownMarketplaces` in `settings.json`, but the real plugin marketplace registry is `~/.claude/plugins/known_marketplaces.json`. Updated to write a `"directory"` source entry there instead. Hook registration still goes to `settings.json` (correct location for hooks).

## What to pick up next

### 1. Re-add external plugin references (blocked on Claude Code)

Once Claude Code's `plugin validate` / `marketplace add` commands support the `git-subdir` source type properly, restore the 3 external entries in `marketplace.json`:
- `exec-feedback` → `ckoglmeier/skills/templates/exec-feedback`
- `research-assistant` → `ckoglmeier/skills/templates/research-assistant`
- `template-strategy-feedback` → `ckoglmeier/skills/templates/template-strategy-feedback`

The Layer 3b tests are already written to validate these schemas — they'll light up as soon as the entries come back.

### 2. Layer 8 — opt-in live validation (deferred)

Add an opt-in test layer gated by `CLASSROOM_VALIDATE_EXTERNAL=1` to `tests/run.sh`. For each object-source entry:
- `git ls-remote` the URL to confirm repo is reachable and ref resolves
- Sparse-clone, then assert `plugin.json` exists at the target path and its `name` field matches the marketplace entry

Plan file with full details: `/Users/ck/.claude/plans/external-template-sources.md` (see "Follow-ups" section).

### 3. Weekly drift-check GitHub Action (deferred)

Natural home for Layer 8 once it exists: cron runs it against `main`, files an issue on drift between classroom's marketplace entries and the upstream skill content.

### 4. SHA pinning + bump workflow (deferred, only if needed)

Currently deferred. When external entries are restored, they'll use `"ref": "main"`. If upstream breakage becomes a real problem, move to SHA pinning with a bump script or Action that opens PRs when upstream templates update.

## Key decisions

- **External references over in-tree copies.** Templates live in `ckoglmeier/skills/templates/`, classroom points at them. Avoids drift, keeps classroom thin. (Temporarily removed due to validator bug.)
- **`family-assistant` is personal.** Moved to `playbooks/` in the skills repo. Not referenced from classroom.
- **`ref: main` pinning.** Accepted the simplicity-over-determinism tradeoff for now.
- **Layer 3b ships now, Layer 8 deferred.** Offline schema validation is in the test suite; live sparse-clone validation comes later once we see rough edges.
- **Original 4 plugins stay in-tree.** They're authored for classroom's audience. The skills repo is CK's personal library — different purpose, different audience.
- **`author` not `owner`.** Claude Code's plugin.json schema uses `author` (with `name` + `contact`). Tests enforce this.
- **Marketplace registry is `known_marketplaces.json`.** Not `extraKnownMarketplaces` in `settings.json`. install.sh writes a `"directory"` source entry there.

## Repo topology

- `ckoglmeier/classroom` — this repo. Marketplace manifest, guide skill, in-tree plugins, install pipeline, tests.
- `ckoglmeier/skills` — CK's personal skill library. `templates/` (shareable, referenced from here), `playbooks/` (personal), `borrowed/` (third-party mirrors).
