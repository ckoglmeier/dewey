# Classroom — session notes

## Current state (2026-05-06)

Classroom is a Claude Code / Cowork / OpenAI Codex plugin marketplace convention. As of v1.3.0 it ships 7 in-tree plugins (28 skills total), the Guide skill, three shell helpers (sync-codex, telemetry, propose), and 14 active test layers (Layer 8 is now opt-in live validation of external entries — gated by `CLASSROOM_VALIDATE_EXTERNAL=1`) covering 370+ tests.

For the full status snapshot (Done / Partial / Deferred / Hosted bucket), the source of truth is now [`docs/roadmap.md`](docs/roadmap.md). This file holds session-level notes and open todos.

## Open todos for next session

Work the user already flagged or that came up mid-session:

### High priority
*(none — what was here is now done; see "Resolved this session" at the bottom)*

### Medium — feature follow-ups
1. **Weekly drift-check GitHub Action** that runs `CLASSROOM_VALIDATE_EXTERNAL=1 bash tests/run.sh` on a cron and files an issue if any external entry's upstream has drifted (repo deleted, plugin renamed, marketplace.json removed). Layer 8 already does the underlying check live — this just schedules it in CI. Useful especially for adopters who add `github` / `npm` external entries.
2. **Cowork plugin marketplace UI audit.** We confirmed Cowork shares `~/.claude/`; we haven't audited how the Cowork plugin browser surfaces Classroom skills (filters, badges, etc.).

### Strategic / design — discussed, parked
3. **Ambient nudge hook** — "I notice you're doing X — there's a skill for that." Pre-skill-routing prompt watcher.
4. **Memory/synthesis pipeline** — daily summary of recent sessions and connected tools to refresh user context.
5. **Chat (claude.ai) distribution** — bundle export for manual upload at minimum; investigate API path for Team/Enterprise plans.
6. **Smart admin onboarding flow.** Today's "Adopting Classroom for your company" section in the README is a 6-step engineer's checklist (fork repo, edit marketplace.json, replace seed skills, etc.). The audience for that work is rarely an engineer — it's the ops or RevOps lead who owns "what skills do my teams use" but doesn't want to clone a repo. Build a conversational flow specifically for first-time org admins:
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

## Resolved this session

- **Inlined `exec-feedback`, `research-assistant`, `template-strategy-feedback`** as in-tree plugins (Option C in `docs/decisions/external-plugin-distribution.md`). 21 new skills landed; one collision resolved (research-assistant's `competitive-analysis` renamed to `research-competitive-analysis`).
- **Layer 3b tightened** to reject `git`/`git-subdir` source types (validator-realignment item).
- **Decision doc marked RESOLVED** with rationale + revisit conditions for if/when third-party publishing becomes a real need.
- v1.3.0 tagged.
- **Layer 8 live validation built** (`tests/lib/validate_external_entry.py`). Opt-in via `CLASSROOM_VALIDATE_EXTERNAL=1`. Per external entry: actually clones the upstream, confirms either single-plugin (`.claude-plugin/plugin.json` with matching name) or marketplace (`.claude-plugin/marketplace.json` with matching plugin entry) layout. Discovered through this work that `github` source type points at *child marketplaces*, not single plugins (e.g. `browserbase/agent-browse` → marketplace with `browse`/`functions`/etc.). Self-test against a deliberately-bad fixture proves the validator catches errors. Adopters who add external entries get the safety net automatically.

## Repo topology

- `ckoglmeier/classroom` — this repo. Marketplace manifest, Guide skill, **7 in-tree plugins (28 skills total)** — these are **seed skills**: starting examples that an adopting org forks and replaces with their own. Plus three shell helpers (sync-codex, telemetry, propose), 13 active test layers, convention + decision docs.
- `ckoglmeier/skills` — CK's personal/active skill library. `templates/`, `playbooks/`, `borrowed/`. Independent from Classroom — they evolve on their own track. The three plugins inlined into Classroom in v1.3.0 (`exec-feedback`, `research-assistant`, `template-strategy-feedback`) were used as starting points for the seed copies; both versions can drift independently from here without that being a problem.

## Quick orientation for a new session

- "What's done?" → `docs/roadmap.md`
- "How does X work?" → docs in `docs/<topic>.md`
- "What's broken or unverified?" → "Open todos" above
- "What changed recently?" → `git log --oneline -20`
- "Tests pass?" → `bash tests/run.sh`
