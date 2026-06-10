# Dewey — session notes

## Current state (2026-05-08)

Dewey is a Claude Code / Cowork / OpenAI Codex plugin marketplace convention (renamed from Classroom in v2.0.0). Ships 7 in-tree plugins (26 skills total), the Guide skill (slash command `/dewey`), three shell helpers (sync-codex, telemetry, propose), 15 active test layers including Layer 4b (Classroom→Dewey migration) and Layer 8 (opt-in live validation of external entries — gated by `DEWEY_VALIDATE_EXTERNAL=1`). 381 tests passing.

For the full status snapshot (Done / Partial / Deferred / Hosted bucket), the source of truth is now [`docs/roadmap.md`](docs/roadmap.md). This file holds session-level notes and open todos.

## Open todos for next session

Work the user already flagged or that came up mid-session:

### High priority
*(none — what was here is now done; see "Resolved this session" at the bottom)*

### Medium — feature follow-ups
*(both former Medium items resolved this session — Layer 8 + drift-check Action; Cowork audit. See "Resolved this session" at the bottom. One follow-up open: visual UI walkthrough by an actual person to verify how categories/tags/multi-skill-plugins/path-files render in Cowork's Browse Plugins panel.)*

### Strategic / design — discussed, parked
1. **Skill-trigger validation tooling** *(replaces what was previously framed as "ambient nudge hook")*. Full plan stored at [`docs/plans/skill-trigger-validation.md`](docs/plans/skill-trigger-validation.md). Three phases (triggers schema + body lint, description quality lint, optional model-based eval) with sequencing, effort estimates, and four decision points to settle before building. Recommendation in the plan: ship Phases 1+2 in one chunk (~3.5h, no API credits), evaluate, then decide on Phase 3.
2. **Multi-organization context — Dewey isn't built for it.** Today Dewey assumes one canonical org: one marketplace, one set of skills, one set of canonical context. Real users (CK in particular) operate across multiple contexts: personal/holdco, Task Engineering, consulting/board/investor work, possibly more. Each has its own positioning, brand voice, ICP, strategy docs, customer accounts. The same skill (e.g. `competitive-analysis`) needs to resolve to *different* canonical context depending on which org the user is acting on right now. Today there's no way to tell Dewey which org is active.

    Possible shapes (none chosen yet):
    - **Org-tagged plugins/context.** Each plugin or context entry declares `org: <id>`. Guide has an "active org" state and filters resolution to that org. Multiple orgs can coexist in one Dewey cache.
    - **Multi-Dewey installs.** Separate caches per org (`~/.claude/dewey-personal/`, `~/.claude/dewey-task/`). Guide knows about all of them and switches active source. Each install is its own marketplace registration.
    - **Active-org as a context bundle.** A single "current org identity" loaded explicitly at session start (`/dewey switch task`). All canonical context resolution then reads from that org's bundle. Same Dewey install, different effective context per session.
    - **Hybrid composition.** Personal Dewey is the base layer; org-specific Deweys layer on top via the existing extension convention. Pull canonical from your personal layer; override with the active org's extensions.

    Questions to answer before building:
    - Is "active org" session-scoped (set once per `/dewey` invocation) or persistent (stored in user prefs)?
    - Does multi-org change the install model (one Dewey or many) or just the resolution model (one Dewey, multiple address spaces)?
    - How does this interact with team-level extensions (`dewey-extensions-<team>`)? Is "team" a sub-concept of "org" or orthogonal?
    - For an enterprise admin running Dewey for their company, the multi-org problem doesn't exist (they're one org). This is more of a personal/consultant/portfolio-operator problem. Worth scoping who this is for before designing.
    - Telemetry implications: extension events should know which org they came from, so the future hosted aggregator can keep org data segregated.

    Bigger than a feature — closer to a v2 architectural question. Worth a design doc (`docs/decisions/multi-org-context.md`) before any code, in the pattern we used for canonical context.

3. **Smart admin onboarding flow.** Today's "Adopting Dewey for your company" section in the README is a 6-step engineer's checklist (fork repo, edit marketplace.json, replace seed skills, etc.). The audience for that work is rarely an engineer — it's the ops or RevOps lead who owns "what skills do my teams use" but doesn't want to clone a repo. Build a conversational flow specifically for first-time org admins:
    - **Discover the org**: company name, industry, primary teams (e.g. Sales, CS, Ops, Eng), key roles per team
    - **Seed the canonical context** the first wave will need (company-identity bundle, ICP, brand voice templates, top-of-funnel positioning) using interactive prompts; output goes through the propose flow
    - **Draft initial path files** per role from a small library of starter templates, tuned by the discovery answers
    - **Suggest external plugins** to pull in (research-assistant for analysts, etc.) and walk through registering them in the marketplace
    - **Demonstrate the loop end-to-end**: install one skill against the seeded context, show the output, then have the admin invite their first 3 users
    - **Optional**: hooks into the future hosted version for "publisher mode" (separate from this consumer Guide). On day one this is local; once hosted exists, the same flow can run there.
    - First use case to demo: weekly status update for the team lead themselves — fast, concrete, no external integrations needed. Once that lands, suggest competitive-analysis next (uses the seeded positioning context — proves the canonical-context value).
    - Open question: does this run as a Guide subcommand (`/dewey admin-setup`) or as its own skill the admin installs first? Subcommand keeps the entry point unified; separate skill keeps the consumer Guide simpler.

### Hosted Dewey bucket (separate product layer)
Not a backlog for this repo per se, but the local data pipe is built to feed it:
- Aggregator + analyzer for forwarded telemetry
- MCP for native push (`propose_skill`, etc.)
- Publisher mode (embedded Claude API conversation for skill/context owners — separate from the consumer Guide)
- Marketplace UI for non-technical authors
- Staged rollouts (canary → global)
- Multi-owner governance / deprecation flows
- Chat distribution backend

## Major decisions / context (current)

- **Three-tier extension model.** Central canonical → company customization (`dewey-extensions-<team>`) → personal extension (`~/.claude/skills/`). Convention-based composition via `extends:` and `extends-context:`.
- **Surfaces are first-class.** `surfaces:` field in `plugin.json` declares Claude Code / Cowork / Codex / Chat support. Lint enforces compatibility down the dependency graph. Layer 11.
- **Canonical context is co-located in plugins.** `context: []` in `plugin.json` declares stable `<plugin>/<bundle>` IDs. Skills declare `requires-context:` and the Guide install flow resolves dependencies before confirming. Convention-based loading (skill body explicitly Reads), no runtime mediator. Three-tier privacy on telemetry. Spec: `docs/canonical-context-design.md`. v1 implementation: Layer 14.
- **Local Dewey captures and forwards data only.** No analysis, no recommendations, no PRs from telemetry. Aggregation happens in the future hosted version. Three-tier opt-out (global env, plugin flag, skill flag) plus body-forwarding gate. Spec: `docs/extension-telemetry.md`.
- **Cowork shares `~/.claude/` with Claude Code.** Verified in a live install. Zero extra work for Cowork support.
- **Codex sync uses symlinks, not copies.** Cache refresh propagates automatically. Skills + canonical context both mirrored. `docs/codex-sync.md`.
- **Propose flow is GitHub-backed.** `gh` does the PR; CODEOWNERS routes review. Auto-forks if no write access. Hosted version will layer richer governance on top — not in this repo.
- **`ref: main` pinning** for external references. Simplicity over determinism. SHA pinning deferred unless we see breakage.
- **`author` not `owner`** in `plugin.json`. Claude Code's schema requires it. Layer 5 enforces.
- **Marketplace registry is `~/.claude/plugins/known_marketplaces.json`** with a `"directory"` source entry, not `extraKnownMarketplaces` in `settings.json`. `install.sh` writes both — settings.json is for hooks only.

## Resolved this session

- **Classroom → Dewey rebrand (v2.0.0).** Major version bump. Renamed the project, marketplace name, slash command (`/classroom` → `/dewey`), helper scripts (`classroom-*.sh` → `dewey-*.sh`), env var namespace (`CLASSROOM_*` → `DEWEY_*`), cache path (`~/.claude/classroom/` → `~/.claude/dewey/`). 625+ path-bearing references swept across 34 files. New `Layer 4b` migration test pre-seeds a fake Classroom install and verifies install.sh hard-renames everything correctly + idempotency. README rewritten to lead with the Dewey Decimal metaphor; haiku rewritten ("Patterns find their shelf — / what one team learns, all teams find, / no one starts alone."). Per the four resolved decisions: migration folded into v2.0.0 (no separate v1.4 release), hard rename (no symlink compat), haiku rewritten for library theme, extension-repo naming `dewey-extensions-*` only (no backward-compat for `classroom-extensions-*`). User performs the GitHub repo rename separately (cannot be done from CLI). 381 tests passing.
- **Inlined `exec-feedback`, `research-assistant`, `template-strategy-feedback`** as in-tree plugins (Option C in `docs/decisions/external-plugin-distribution.md`). 21 new skills landed; one collision resolved (research-assistant's `competitive-analysis` renamed to `research-competitive-analysis`).
- **Layer 3b tightened** to reject `git`/`git-subdir` source types (validator-realignment item).
- **Decision doc marked RESOLVED** with rationale + revisit conditions for if/when third-party publishing becomes a real need.
- v1.3.0 tagged.
- **Layer 8 live validation built** (`tests/lib/validate_external_entry.py`). Opt-in via `DEWEY_VALIDATE_EXTERNAL=1`. Per external entry: actually clones the upstream, confirms either single-plugin (`.claude-plugin/plugin.json` with matching name) or marketplace (`.claude-plugin/marketplace.json` with matching plugin entry) layout. Discovered through this work that `github` source type points at *child marketplaces*, not single plugins (e.g. `browserbase/agent-browse` → marketplace with `browse`/`functions`/etc.). Self-test against a deliberately-bad fixture proves the validator catches errors. Adopters who add external entries get the safety net automatically.
- **Cowork audit** (`docs/cowork-audit.md`). Filesystem-level findings: Cowork shares `~/.claude/plugins/` with Claude Code (no separate registration); has a parallel DXT-extension system that Dewey doesn't touch; ignores our `surfaces:` field in its UI; doesn't badge-source-of-marketplace; scheduled-tasks are themselves SKILL.md directories so wrapping a Dewey skill for Cowork's scheduler is trivial. Updated `docs/scheduling.md` with the Cowork wrapper pattern. One open follow-up: visual UI walkthrough to verify rendering of categories/tags/path-files/multi-skill-plugins.
- **claude.ai distribution research** (`docs/research/claude-ai-distribution.md`). Investigated all four Anthropic distribution channels that touch claude.ai: Skills API (developers, not consumers), claude.ai per-user upload (manual, painful), claude.ai org-wide provisioning (Team/Enterprise admin, no public API), Cowork private plugin marketplaces (admin, private GitHub source in beta). Conclusion: build nothing speculatively. The integration point Dewey needs (link a Git repo as the org skill source) is open feature request [anthropics/claude-code#28729](https://github.com/anthropics/claude-code/issues/28729) — acknowledged by Anthropic, no timeline. When it ships, slot-in cost is ~half a day of docs. Watch the issue. Cross-surface sync is also impossible today (each surface is its own pipe) — even the perfect feature only lights up one surface at a time.
- **Weekly drift-check GitHub Action** (`.github/workflows/drift-check.yml`). Runs Layer 8 (`DEWEY_VALIDATE_EXTERNAL=1`) on a Monday-morning cron + manual dispatch. On failure, opens or updates an issue tagged `external-drift` with the test output. On success, closes any open drift issues with a resolved note. Idempotent issue management means the inbox doesn't bloat. Trivially passes today (zero external entries to validate); becomes load-bearing the moment any adopter adds one.

## Repo topology

- `ckoglmeier/dewey` — this repo. Marketplace manifest, Guide skill, **7 in-tree plugins (26 skills total)** — these are **seed skills**: starting examples that an adopting org forks and replaces with their own. Plus three shell helpers (sync-codex, telemetry, propose), 13 active test layers, convention + decision docs.
- `ckoglmeier/skills` — CK's personal/active skill library. `templates/`, `playbooks/`, `borrowed/`. Independent from Dewey — they evolve on their own track. The three plugins inlined into Dewey in v1.3.0 (`exec-feedback`, `research-assistant`, `template-strategy-feedback`) were used as starting points for the seed copies; both versions can drift independently from here without that being a problem.

## Quick orientation for a new session

- "What's done?" → `docs/roadmap.md`
- "How does X work?" → docs in `docs/<topic>.md`
- "What's broken or unverified?" → "Open todos" above
- "What changed recently?" → `git log --oneline -20`
- "Tests pass?" → `bash tests/run.sh`
