# Classroom — session notes

## Current state (2026-05-06)

Classroom is a Claude Code / Cowork / OpenAI Codex plugin marketplace convention. It ships 4 in-tree plugins, the Guide skill, four shell helpers (schedule, sync-codex, telemetry, propose), and 14 test layers covering 213+ tests.

For the full status snapshot (Done / Partial / Deferred / Hosted bucket), the source of truth is now [`docs/roadmap.md`](docs/roadmap.md). This file holds session-level notes and open todos.

## Open todos for next session

Work the user already flagged or that came up mid-session:

### High priority
1. **Verify scheduled execution end-to-end.** `classroom-schedule.sh` is built and unit-tested (Layer 8) but no test or manual run has confirmed a real scheduled job actually fires, has working `ANTHROPIC_API_KEY` in scope, and produces a usable log entry. Until verified, schedule is in the **Partial** column of the roadmap.
2. **Re-add external plugin references** (still blocked on Claude Code). Once `marketplace add` accepts `git-subdir`, restore the 3 entries — Layer 3b is already written:
   - `exec-feedback` → `ckoglmeier/skills/templates/exec-feedback`
   - `research-assistant` → `ckoglmeier/skills/templates/research-assistant`
   - `template-strategy-feedback` → `ckoglmeier/skills/templates/template-strategy-feedback`
3. **Stale `AGENTS.md` in working tree.** A test run with `--agents-md` once produced `AGENTS.md` at repo root with content that mistakenly substituted "Codex" for "Claude Code" in CLAUDE.md-style notes. It's in `git status` as untracked. Decide: delete, or regenerate cleanly via `bash classroom-sync-codex.sh --agents-md .` (but that targets project-level use, not the Classroom repo itself — probably just delete).

### Medium — feature follow-ups
4. **Layer 8 opt-in live validation** for external `git-subdir` entries. Gated by `CLASSROOM_VALIDATE_EXTERNAL=1`. Sparse-clone, confirm `plugin.json` exists at the target path, name matches. Plan: `~/.claude/plans/external-template-sources.md` ("Follow-ups" section).
5. **Weekly drift-check GitHub Action** for Layer 8 — natural home once it exists.
6. **Cowork plugin marketplace UI audit.** We confirmed Cowork shares `~/.claude/`; we haven't audited how the Cowork plugin browser surfaces Classroom skills (filters, badges, etc.).
7. **Schedule observability.** A `/classroom schedule status` command that shows what's scheduled, last run, last failure. Today the user has to grep launchctl/crontab + log files manually.

### Strategic / design — discussed, parked
8. **Headless beyond cron** — webhook/event-triggered runs, long-running agentic loops, output sinks beyond log files. Each needs its own design pass.
9. **Ambient nudge hook** — "I notice you're doing X — there's a skill for that." Pre-skill-routing prompt watcher.
10. **Memory/synthesis pipeline** — daily summary of recent sessions and connected tools to refresh user context.
11. **Chat (claude.ai) distribution** — bundle export for manual upload at minimum; investigate API path for Team/Enterprise plans.
12. **Context-on-demand via `/classroom load` — RESOLVED, ready to build.**

    Decisions (CK, 2026-05-06):
    - **No always-loaded / global context.** Nothing should load for every conversation. The bytes-per-conversation tax is wrong, and it makes context invisible to the user.
    - **Load on demand via the Guide.** New subcommand `/classroom load [topic]`. The Guide reads the user's topic, scans installed context bundles' titles/descriptions, and either loads the match or — if ambiguous or empty — lists candidates and asks.
    - **Naming convention: each bundle's primary file is `context.md`.** Standardize so the Guide always knows what to read. The existing demonstrator (`plugins/competitive-intelligence/context/positioning/positioning.md`) gets renamed to `plugins/competitive-intelligence/context/positioning/context.md`. The `path:` entry in `plugin.json` is updated accordingly. A bundle can still ship additional supporting files in the same dir, but `context.md` is the canonical entry point.

    Implementation sketch (next session):
    - **Convention update**: rename `positioning.md` → `context.md`; update `plugin.json` path; update the in-skill load instructions in `competitive-analysis/SKILL.md` (both Claude Code/Cowork and Codex paths).
    - **Lint update** in `tests/lib/check_requires_context.py` and Layer 14: warn (not fail) if a bundle's primary file isn't named `context.md`. Don't break existing v1 bundles in the wild that may use other names.
    - **New Guide §11 Load**:
      1. Parse `$1` as topic (optional).
      2. Walk `~/.claude/classroom/plugins/*/.claude-plugin/plugin.json`, collect every `context: []` entry's `id`, `title`, `description`.
      3. If `$1` is empty: present the full list grouped by plugin, ask which to load.
      4. If `$1` matches exactly one bundle's `id` or `title` (case-insensitive substring): confirm and load.
      5. If `$1` matches multiple: list the matches, ask which.
      6. "Load" means: Read the resolved `context.md` into the conversation. The Guide can then summarize what it loaded and tell the user the content is now available for the rest of the conversation.
    - **Routing**: add `load` to argument-hint, the routing table, and the menu.
    - **Docs**: update `docs/canonical-context.md` with the load-on-demand pattern and the `context.md` naming convention. Update `docs/canonical-context-design.md`'s "v1 decisions" with the resolution.
    - **Tests**: Layer 14 — bundle's primary file is `context.md` (warn); Guide §11 references the helper / load mechanic.

    Why this is the right answer: it keeps context invisible-when-not-needed and explicit-when-it-is, avoids the always-loaded tax, and matches a real use case ("put the brand voice in this conversation right now"). It does NOT solve "every conversation should know our company name" — that's an explicit non-goal; if you want that, you say it once and it sticks for the rest of the session.

### Hosted Classroom bucket (separate product layer)
Not a backlog for this repo per se, but the local data pipe is built to feed it:
- Aggregator + analyzer for forwarded telemetry
- MCP for native push (`propose_skill`, etc.)
- Publisher mode (embedded Claude API conversation for skill/context owners — separate from the consumer Guide)
- Marketplace UI for non-technical authors
- Staged rollouts (canary → global)
- Multi-owner governance / deprecation flows
- Chat distribution backend

## Major decisions / context (current)

- **Three-tier extension model.** Central canonical → company customization (`classroom-extensions-<team>`) → personal extension (`~/.claude/skills/`). Convention-based composition via `extends:` and `extends-context:`.
- **Surfaces are first-class.** `surfaces:` field in `plugin.json` declares Claude Code / Cowork / Codex / Chat support. Lint enforces compatibility down the dependency graph. Layer 11.
- **Canonical context is co-located in plugins.** `context: []` in `plugin.json` declares stable `<plugin>/<bundle>` IDs. Skills declare `requires-context:` and the Guide install flow resolves dependencies before confirming. Convention-based loading (skill body explicitly Reads), no runtime mediator. Three-tier privacy on telemetry. Spec: `docs/canonical-context-design.md`. v1 implementation: Layer 14.
- **Local Classroom captures and forwards data only.** No analysis, no recommendations, no PRs from telemetry. Aggregation happens in the future hosted version. Three-tier opt-out (global env, plugin flag, skill flag) plus body-forwarding gate. Spec: `docs/extension-telemetry.md`.
- **Cowork shares `~/.claude/` with Claude Code.** Verified in a live install. Zero extra work for Cowork support.
- **Codex sync uses symlinks, not copies.** Cache refresh propagates automatically. Skills + canonical context both mirrored. `docs/codex-sync.md`.
- **Propose flow is GitHub-backed.** `gh` does the PR; CODEOWNERS routes review. Auto-forks if no write access. Hosted version will layer richer governance on top — not in this repo.
- **`ref: main` pinning** for external references. Simplicity over determinism. SHA pinning deferred unless we see breakage.
- **`author` not `owner`** in `plugin.json`. Claude Code's schema requires it. Layer 5 enforces.
- **Marketplace registry is `~/.claude/plugins/known_marketplaces.json`** with a `"directory"` source entry, not `extraKnownMarketplaces` in `settings.json`. `install.sh` writes both — settings.json is for hooks only.

## Repo topology

- `ckoglmeier/classroom` — this repo. Marketplace manifest, Guide skill, in-tree plugins (4), four shell helpers, 14 test layers, convention docs.
- `ckoglmeier/skills` — CK's personal skill library. `templates/` (shareable, referenced from here when validator unblocks), `playbooks/` (personal), `borrowed/` (third-party mirrors).

## Quick orientation for a new session

- "What's done?" → `docs/roadmap.md`
- "How does X work?" → docs in `docs/<topic>.md`
- "What's broken or unverified?" → "Open todos" above
- "What changed recently?" → `git log --oneline -20`
- "Tests pass?" → `bash tests/run.sh`
