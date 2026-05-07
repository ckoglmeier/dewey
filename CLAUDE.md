# Classroom — session notes

## Current state (2026-05-06)

Classroom is a Claude Code / Cowork / OpenAI Codex plugin marketplace convention. It ships 4 in-tree plugins, the Guide skill, four shell helpers (schedule, sync-codex, telemetry, propose), and 14 test layers covering 213+ tests.

For the full status snapshot (Done / Partial / Deferred / Hosted bucket), the source of truth is now [`docs/roadmap.md`](docs/roadmap.md). This file holds session-level notes and open todos.

## Open todos for next session

Work the user already flagged or that came up mid-session:

### High priority
1. **Re-add external plugin references — still blocked, but the blocker is bigger than "git-subdir."** Verified against Claude Code v2.1.47 (2026-05-06):

   - **`marketplace add` schema acceptance** by source type:
     - `url`, `github`, `npm` → accepted
     - `git`, `git-subdir` → rejected with `Invalid input` (even using a literal copy of the official marketplace's working `git-subdir` semgrep entry, so this isn't about our shape — `git-subdir` was apparently grandfathered for `claude-plugins-official` and is no longer accepted for new marketplaces)
   - **Sub-path support at install time:** `github` source schema accepts a `path:` (or `subdir:` / `directory:`) field, but the install fetcher *silently ignores it* and pulls the entire upstream repo. Confirmed by installing `{source: github, repo: ckoglmeier/skills, path: templates/exec-feedback}` — install reported success but the cache contained the whole `ckoglmeier/skills` tree, no `.claude-plugin/plugin.json` at the cache root.

   So the real blocker isn't "wait for `git-subdir`" — it's that **no schema-accepted source type honors a sub-path at install time**. Three real paths forward:

   - **(a) Promote each template to its own GitHub repo** — `ckoglmeier/skill-exec-feedback`, etc. Then `{source: github, repo: ckoglmeier/skill-exec-feedback}` works cleanly without sub-paths. Cleanest long-term; maintenance overhead of N repos.
   - **(b) Publish each as an npm package** under `@ck-skills/<name>`. `npm` source is accepted and honored. One publish step per skill update; npm registry as the distribution mechanism.
   - **(c) Inline the three templates into Classroom's `plugins/` directory.** Defeats the "Classroom is a thin pointer to upstream" goal but unblocks today.

   Pick one before retrying. Layer 3b's offline schema validator should be updated to reject `git`/`git-subdir` source types since they no longer pass `marketplace add` — currently it accepts them and gives false confidence.
2. **Stale `AGENTS.md` in working tree.** A test run with `--agents-md` once produced `AGENTS.md` at repo root with content that mistakenly substituted "Codex" for "Claude Code" in CLAUDE.md-style notes. It's in `git status` as untracked. Decide: delete, or regenerate cleanly via `bash classroom-sync-codex.sh --agents-md .` (but that targets project-level use, not the Classroom repo itself — probably just delete).

### Medium — feature follow-ups
3. **Layer 8 opt-in live validation** for external `git-subdir` entries. Gated by `CLASSROOM_VALIDATE_EXTERNAL=1`. Sparse-clone, confirm `plugin.json` exists at the target path, name matches. Plan: `~/.claude/plans/external-template-sources.md` ("Follow-ups" section). Note: the old "Layer 8" was the schedule helper (now removed); this slot is free for the live-validation layer when we build it.
4. **Weekly drift-check GitHub Action** for the live-validation layer — natural home once it exists.
5. **Cowork plugin marketplace UI audit.** We confirmed Cowork shares `~/.claude/`; we haven't audited how the Cowork plugin browser surfaces Classroom skills (filters, badges, etc.).

### Strategic / design — discussed, parked
6. **Ambient nudge hook** — "I notice you're doing X — there's a skill for that." Pre-skill-routing prompt watcher.
7. **Memory/synthesis pipeline** — daily summary of recent sessions and connected tools to refresh user context.
8. **Chat (claude.ai) distribution** — bundle export for manual upload at minimum; investigate API path for Team/Enterprise plans.
9. **Smart admin onboarding flow.** Today's "Adopting Classroom for your company" section in the README is a 6-step engineer's checklist (fork repo, edit marketplace.json, replace seed skills, etc.). The audience for that work is rarely an engineer — it's the ops or RevOps lead who owns "what skills do my teams use" but doesn't want to clone a repo. Build a conversational flow specifically for first-time org admins:
    - **Discover the org**: company name, industry, primary teams (e.g. Sales, CS, Ops, Eng), key roles per team
    - **Seed the canonical context** the first wave will need (company-identity bundle, ICP, brand voice templates, top-of-funnel positioning) using interactive prompts; output goes through the propose flow
    - **Draft initial path files** per role from a small library of starter templates, tuned by the discovery answers
    - **Suggest external plugins** to pull in (research-assistant for analysts, etc.) and walk through registering them in the marketplace
    - **Demonstrate the loop end-to-end**: install one skill against the seeded context, show the output, then have the admin invite their first 3 users
    - **Optional**: hooks into the future hosted version for "publisher mode" (separate from this consumer Guide). On day one this is local; once hosted exists, the same flow can run there.
    - First use case to demo: weekly status update for the team lead themselves — fast, concrete, no external integrations needed. Once that lands, suggest competitive-analysis next (uses the seeded positioning context — proves the canonical-context value).
    - Open question: does this run as a Guide subcommand (`/classroom admin-setup`) or as its own skill the admin installs first? Subcommand keeps the entry point unified; separate skill keeps the consumer Guide simpler.

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
