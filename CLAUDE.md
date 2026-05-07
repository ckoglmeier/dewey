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
12. **Global context model — without putting context everywhere.** v1 canonical context is explicit per-skill (`requires-context:`). That's right for skill-specific dependencies but wrong for facts that should be true *everywhere* — company name, industry, fiscal year, top-level brand voice. Forcing every skill to declare them is repetitive; pasting them into every prompt is the single-player problem we're trying to solve. Options to think through:
    - **Always-loaded bundle** declared at the marketplace or path-file level (e.g. `paths/sales-ae.md` lists "always-load: company/identity"). Loaded once per session.
    - **A SessionStart hook** that injects a small global-context block ahead of any skill, sourced from a designated plugin (e.g. `company-truth/global`).
    - **Implicit dependency**: skills that don't declare `requires-context:` automatically inherit a configured global bundle. Risk: surprising and hard to debug.
    - **Trade-off to manage**: every byte loaded globally is loaded for every conversation. Need a small, opinionated default and a way for users to opt OUT for narrow tasks. The 80/300KB lint thresholds we have for declared context don't apply to what's always-loaded — needs its own size discipline.
    - Open questions: who curates the global bundle (org admin? team lead? Guide on first run?); does it compose three-tier the same way (central global → team global overlay → personal); does it count against the same telemetry events.

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
