# Plan: Go-to-market readiness

**Status:** Proposed, not started.
**Date:** 2026-06-10
**Scope:** everything to build before putting Dewey on the market. Supersedes nothing — composes [admin-onboarding.md](admin-onboarding.md), [hosted-dewey.md](hosted-dewey.md), and [skill-trigger-validation.md](skill-trigger-validation.md) Phase 3 into one delivery sequence with two new workstreams (supply-chain hardening, Guide eval harness).

## Framing

Going to market reorders priorities around two questions: *what does a stranger hit in their first hour* (WS1, WS5), and *what does their security team ask in week two* (WS2). WS3 keeps the demo from breaking; WS4 makes the differentiator visible. Multi-org, hosted stages 2–5, and any marketplace UI are explicitly out of scope — see "Not building" below.

## Workstream summary

| WS | What | Effort | Model tier | Depends on |
|---|---|---|---|---|
| 1 | Admin onboarding skill (+ fork-less trial) | ~11h | Sonnet build, strong-model review on conversation design | — |
| 2 | Supply-chain hardening: releases, pinning, checksums | ~1.5d | Sonnet build, **strong-model review mandatory** (installer + refresh) | — |
| 3 | Guide + flow eval harness | ~1d | Sonnet harness; Haiku as the runtime eval model | WS1 (covers its flows too) |
| 4 | Hosted Stage 1, demo-grade + telemetry org field | ~2d | Sonnet; strong-model review on the ingest schema | Gate G0 |
| 5 | Cowork Browse Plugins walkthrough | ~0.5d human | none — this one is yours | — |

Critical path: WS1 → WS3. WS2 parallel from day one. WS4 starts when G0 clears. WS5 anytime, before launch.

## Gate G0 — business decisions before WS4 architecture

Settle before WS4 starts, because they shape its architecture:
1. **Where does hosted run** — your infra (multi-tenant SaaS) vs. customer VPC vs. both? Determines auth model and whether the ingest is one service or a deployable artifact.
2. **Pricing surface** — is telemetry volume, seats, or orgs the metered unit? Determines what the event store must count reliably from day one.
3. **Demo posture** — synthetic-data demo only, or a design-partner org live? Determines how production-grade Stage 1's ingest needs to be at launch.

These are decisions, not designs — an afternoon of answers, captured as a short addendum to [hosted-dewey.md](hosted-dewey.md).

## WS1 — Admin onboarding

Plan already settled in [admin-onboarding.md](admin-onboarding.md) (five phases, ~11h). Two GTM amendments:

- **Resolve open question #2 → fork-less trial, yes.** Stage 5's demo must run against the reference marketplace *before* any fork exists: one install command → working `weekly-status-update` demo in minute five → "want this with your company's context? let's fork." Time-to-first-value is the funnel's top.
- **Acceptance bar raised:** the phase-5 role-played dry-run eval is no longer optional polish — it gates launch. A second author-blind run with a "skeptical, busy" persona variant is added.

## WS2 — Supply-chain hardening

Today: installer defaults to `ref: main`; the refresh script swaps in whatever main contains, nightly, unattended. The roadmap's "`ref: main` pinning — simplicity over determinism; SHA pinning deferred unless we see breakage" was the right call for personal use and is disqualifying in a security review. "Breakage" has arrived in the form of a buyer.

Deliverables:
1. **Release process.** Tagged releases (`vX.Y.Z`) with a generated changelog; a `RELEASING.md` checklist; tags become the unit customers consume.
2. **Pinned-by-default install.** `install.sh` defaults `DEWEY_REF` to the latest release tag (resolved via the GitHub releases API, with `main` available only by explicit override). Per-release SHA-256 checksums published as release assets; the installer fetches and verifies by default — the existing `verify_sha256()` path becomes mandatory rather than opt-in-via-env.
3. **Refresh pinning.** The generated refresh script tracks the release channel, not main: it upgrades tag-to-tag, verifying checksums, and logs the version transition. `DEWEY_REFRESH_CHANNEL=main` remains for dev.
4. **Tests.** Layer 6/7 extensions: install-from-tag, checksum-required failure mode, refresh declines an unverifiable swap. A fixture release in the test sandbox (no network).
5. **One-page security overview** (`docs/security.md`): what runs when, what's verified, what telemetry leaves the machine and the three-tier opt-out — written for a buyer's security reviewer, not a contributor.

Model: Sonnet builds; **strong-model review is mandatory** — this workstream touches `install.sh` and the refresh generator, the two highest-blast-radius files in the repo. Verification: full suite + a clean-VM install from a real tag.

## WS3 — Guide + flow eval harness

The Guide's conversational flows have zero runtime coverage (audit finding, accepted then; not acceptable for a product). Extends the Phase 3 design from [skill-trigger-validation.md](skill-trigger-validation.md):

1. **Trigger routing eval** as specced (skill × trigger → does the router pick the right skill). Haiku, ~$0.10/run, cached by content hash.
2. **Guide flow eval:** scripted personas drive `/dewey recommend`, `install` (mocked confirm), `extend`, and the admin-setup flow (WS1) end-to-end via the Agent SDK against a sandbox cache. Assertions on outcomes (right plugin recommended for the path file, confirm-before-acting honored, correct files written), not on wording.
3. **CI wiring:** runs on PRs touching `guide/`, `plugins/admin/`, or any SKILL.md; nightly otherwise. Opt-in env-gated like Layer 8 (`DEWEY_EVAL=1` + API key) so the offline suite stays hermetic.
4. **Launch bar:** ≥90% trigger-routing accuracy; 100% of Guide-flow assertions green on the pinned model.

Model: Sonnet builds the harness; Haiku is the eval runtime. Effort ~1d (the skill-creator precedent and Layer 8's opt-in pattern are both reusable).

## WS4 — Hosted Stage 1, demo-grade

Builds [hosted-dewey.md](hosted-dewey.md) Stage 1, consciously overriding its "audience of one" gate — going to market *is* the demand signal that gate was waiting for. Scope:

1. **Telemetry `org` field** (multi-org Phase 4, ~1h — do first so the ingest schema never migrates).
2. **`dewey-telemetry.sh forward`**: batched sender honoring the documented endpoint contract and every opt-out tier; fails silent; never blocks a session.
3. **Ingest service**: authenticated POST per the contract; append-only store keyed (org, plugin, skill, event). Architecture per G0's hosting answer.
4. **Weekly digest**: per-org maintainer email/Slack — "N users extended X; M added a Slack lookup" — template-rendered, no UI.
5. **Synthetic demo seed**: a generator producing a plausible 90-day, 25-user event history so the digest demos without real traffic, clearly labeled in demo mode.

Model: Sonnet throughout; **strong-model review on the ingest event schema** — it is the interface every later hosted stage consumes, and the one artifact here that must be right the first time. Verification: contract tests both sides of the endpoint; an end-to-end run from a sandbox `skill_invoke` event to a rendered digest line.

## WS5 — Cowork walkthrough (human)

Pre-launch due diligence, not a backlog nit: open Cowork's Browse Plugins panel against the reference marketplace and verify categories, tags, multi-skill plugins, and path files render acceptably; screenshot everything into `docs/cowork-audit.md`. Any rendering defect is triaged as launch-blocking or cosmetic *then*, not discovered by a prospect. Half a day, requires a human (you).

## Schedule shape

Assuming roughly half-time attention:

- **Week 1:** WS1 phases 1–3 ∥ WS2 items 1–3. WS5 whenever Cowork is open.
- **Week 2:** WS1 phases 4–5 → WS3 ∥ WS2 items 4–5. G0 decisions settled mid-week.
- **Week 3:** WS4. Launch-readiness review at the end: all five acceptance bars below.

## Launch-readiness checklist

- [ ] A stranger reaches a working demo in ≤5 minutes from one install command (WS1, timed dry-run)
- [ ] Install + refresh consume only tagged, checksum-verified releases by default; `docs/security.md` exists (WS2, clean-VM test)
- [ ] Eval harness green at the launch bar on a pinned model; wired into CI (WS3)
- [ ] The extension-loop digest demos from synthetic data; real ingest works end-to-end from one live event (WS4)
- [ ] Cowork rendering verified and documented; defects triaged (WS5)
- [ ] Full offline suite green (383+ — each WS adds tests)

## Not building (and why)

- **Multi-org** — consultant feature; each paying company is one org. Design ready in [multi-org-context.md](../decisions/multi-org-context.md) when demand shows.
- **Hosted stages 2–5** — the analyzer needs real traffic to be honest; UI is the most expensive thing to build for nobody. Gates in [hosted-dewey.md](hosted-dewey.md) stand.
- **Marketplace web UI** — first authors are fine in the PR flow.
- **Pricing/packaging/website** — business work, tracked at G0, not in this repo.
