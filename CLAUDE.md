# Dewey — session notes

## Current state (2026-06-10)

Dewey is a Claude Code / Cowork / OpenAI Codex plugin marketplace convention (renamed from Classroom in v2.0.0). Ships 8 in-tree plugins (27 skills total), the Guide skill (slash command `/dewey`), three shell helpers (sync-codex, telemetry, propose), 17 active test layers including Layer 4b (Classroom→Dewey migration) and Layer 8 (opt-in live validation of external entries — gated by `DEWEY_VALIDATE_EXTERNAL=1`). 455 tests passing, plus a separate 54-test hosted Python unit suite. The test suite is split into per-layer files under `tests/layers/` with a thin `tests/run.sh` harness; CI now runs the full suite on every push/PR via `.github/workflows/test.yml`. Dewey is now a buyable open-core product: the local convention is free; an org license key activates hosted features (telemetry forwarding + weekly digest). See docs/plans/go-to-market.md.

For the full status snapshot (Done / Partial / Deferred / Hosted bucket), the source of truth is now [`docs/roadmap.md`](docs/roadmap.md). This file holds session-level notes and open todos.

## Open todos for next session

Work the user already flagged or that came up mid-session:

### High priority
*(none — what was here is now done; see "Resolved this session" at the bottom)*

### Medium — feature follow-ups
- **Phase 3 trigger eval (optional)** — model-based routing eval per docs/plans/skill-trigger-validation.md Phase 3. Opt-in like Layer 8, needs API credits (~$0.10/run on Haiku). Decide after living with the Layer 15 lint for a while.
- **Argument-hint backfill** on ~10 high-traffic skills — pending the open question of whether argument-hint matters for plugin skills (vs. only the Guide).
- **Cowork Browse Plugins UI walkthrough** — still needs a human to verify how categories/tags/multi-skill-plugins/path-files render in Cowork's Browse Plugins panel (unchanged).

### GTM follow-ups (post-merge)
- **Cowork Browse Plugins walkthrough** — still needs a human (WS5).
- **Connect a real payment provider account** (Stripe/Paddle) — human step; service implements the webhook contract, no live payments until then. See hosted/RUNBOOK.md.
- **Run the full eval** (DEWEY_EVAL=1 + a backend) pre-release; it costs API credits and is not in PR CI.
- **Hosted stages 2-5** (analyzer, MCP push, publisher mode, UI) — gated per docs/plans/hosted-dewey.md.

### Strategic / design — discussed, parked
1. **Multi-organization context — Dewey isn't built for it.** Design doc: `docs/decisions/multi-org-context.md`. Today Dewey assumes one canonical org; real users (consultants, portfolio operators) need per-org context resolution. The same skill needs to resolve to different canonical context depending on which org is active. Bigger than a feature — closer to a v2 architectural question.

2. **Smart admin onboarding flow.** Plan: `docs/plans/admin-onboarding.md`. Today's README adoption path is a 6-step engineer's checklist; the real audience is an ops/RevOps lead who doesn't want to clone a repo. Build a conversational first-time flow that discovers the org, seeds canonical context, and demonstrates the loop end-to-end.

### Hosted Dewey bucket (separate product layer)
Not a backlog for this repo per se, but the local data pipe is built to feed it:
- Sequencing plan now at `docs/plans/hosted-dewey.md`.
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

- **Go-to-market build (PR #4).** Shipped a working, buyable open-core Dewey across five workstreams: (1) admin onboarding plugin `dewey-admin-setup` with fork-less trial; (2) supply-chain hardening — install/refresh now pin to checksum-verified GitHub releases by default, docs/security.md for buyers; (3) hosted service under hosted/ (stdlib-only Python: SQLite store with hashed-at-rest license keys, HMAC Stripe-shaped checkout webhook, bearer-auth event ingest, per-org weekly digest, synthetic demo seed); (4) CLI open-core licensing — install.sh accepts DEWEY_LICENSE_KEY, dewey-telemetry.sh forward pushes batches; the open-core guarantee (no license ever degrades local function) is test-asserted; (5) eval harness under evals/ run on the advanced model: routing 93.8% / flows 100%.
- **Adversarial security review of the money path.** Returned NO-SHIP on two HIGH issues (webhook replay via missing event id; validate endpoint leaking org/plan/status) — both fixed and regression-tested before PR #4. Verified the full purchase→install→forward→digest loop end-to-end.
- **Repo audit + remediation (PR #2, merged).** Full audit graded B+. Fixed: CI for the test suite (`.github/workflows/test.yml` — previously the 381 tests never ran in CI), 6 Python file-handle leaks in `tests/lib/`, stale Classroom references (CODEOWNERS header, skill counts), README 'Upgrading from Classroom' section, `requirements.txt`.
- **Layer 15: triggers + description quality lint (Phases 1+2 of the skill-trigger plan).** All 25 user-invocable skills now declare 3–5 realistic `triggers:`. New lints: `check_triggers.py` (missing/overlong/zero-overlap triggers fail; <3 warns) and `check_description_quality.py` (length 50–250, no vague-verb leads). The description lint caught a latent bug: folded `description: >` blocks bypassed Layer 2's length check — 20 over-length descriptions rewritten, embedded trigger prose moved into `triggers:` fields. `synthesis` is `user-invocable: false` and exempt (lint fails it if triggers appear — routing must go via the orchestrator). `docs/skill-triggers.md` is the author reference; `pr-checklist.md` now distinguishes lint-enforced rules from reviewer judgment calls.
- **tests/run.sh split into per-layer files** under `tests/layers/` (16 files), sourced by a ~110-line harness. Verified identical: 383/383, zero test-name drift, failures still propagate (red-test), missing layer file aborts FATAL.
- **Two portability fixes from first-ever Linux CI run:** Layer 6's stripped no-git PATH now includes gzip + GNU userland (GNU tar execs gzip for `-z`; macOS bsdtar doesn't); `install.sh` checksum verification now prefers `sha256sum` with `shasum` fallback (`shasum` is Perl, absent on minimal Linux images) — same helper embedded in the generated refresh script, which skips the swap when it can't verify.

## Repo topology

- `ckoglmeier/dewey` — this repo. Marketplace manifest, Guide skill, **8 in-tree plugins (27 skills total)** — these are **seed skills**: starting examples that an adopting org forks and replaces with their own. Plus three shell helpers (sync-codex, telemetry, propose), 17 active test layers, convention + decision docs.
- `ckoglmeier/skills` — CK's personal/active skill library. `templates/`, `playbooks/`, `borrowed/`. Independent from Dewey — they evolve on their own track. The three plugins inlined into Dewey in v1.3.0 (`exec-feedback`, `research-assistant`, `template-strategy-feedback`) were used as starting points for the seed copies; both versions can drift independently from here without that being a problem.

## Quick orientation for a new session

- "What's done?" → `docs/roadmap.md`
- "How does X work?" → docs in `docs/<topic>.md`
- "What's broken or unverified?" → "Open todos" above
- "What changed recently?" → `git log --oneline -20`
- "Tests pass?" → `bash tests/run.sh`
