# Plan: Go-to-market readiness

**Status:** Proposed, not started.
**Date:** 2026-06-10
**Scope:** everything to build before putting Dewey on the market. Supersedes nothing — composes [admin-onboarding.md](admin-onboarding.md), [hosted-dewey.md](hosted-dewey.md), and [skill-trigger-validation.md](skill-trigger-validation.md) Phase 3 into one delivery sequence with three new workstreams (supply-chain hardening, Guide eval harness, purchase & entitlement).

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
| 6 | Purchase & entitlement: checkout → license → gated install | ~3.5d | Sonnet; strong-model review on entitlement API + installer changes | Gate G0 (items 4–5), WS2 |

Critical path: WS1 → WS3, and G0 → WS4/WS6 (WS6 also needs WS2's release machinery). WS2 parallel from day one. WS5 anytime, before launch.

## Gate G0 — business decisions before WS4 architecture

Settle before WS4 starts, because they shape its architecture:
1. **Where does hosted run** — your infra (multi-tenant SaaS) vs. customer VPC vs. both? Determines auth model and whether the ingest is one service or a deployable artifact.
2. **Pricing surface** — is telemetry volume, seats, or orgs the metered unit? Determines what the event store must count reliably from day one.
3. **Demo posture** — synthetic-data demo only, or a design-partner org live? Determines how production-grade Stage 1's ingest needs to be at launch.
4. **What exactly is paid** — see WS6's framing decision: fully gated vs. open-core. Determines whether the installer needs entitlement at all or only the hosted features do.
5. **Merchant of record** — Stripe (you handle global sales tax) vs. Paddle/Lemon Squeezy (they do, for a larger cut). A B2B product sold to companies in multiple jurisdictions strongly favors a merchant-of-record unless you already have tax operations.

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

## WS6 — Purchase & entitlement

The pipeline: **buy → receive a license key → one install command that works.** Friction anywhere in that chain is lost revenue; complexity anywhere in it is support burden. Design accordingly.

### Framing decision first (G0 item 4): what does the license gate?

- **Option A — fully gated:** the CLI tarball itself requires a valid license to download. Strongest control, but it complicates everything downstream: every refresh needs a live entitlement check, air-gapped installs break, and the convention's adoption story ("your whole team installs in minutes") now routes through a license server's uptime.
- **Option B — open-core (recommended):** the local convention (installer, Guide, plugins, lint) stays freely installable; the license activates the *hosted* features — telemetry forwarding, the digest, and future stages. The thing being sold is the loop, which is genuinely hosted-side; the local CLI is the funnel, not the product. Gating the funnel shrinks it.

The plan below is written for **B**, with the deltas for A noted at the end. If G0 lands on A, add ~1.5d.

### Deliverables

1. **Checkout** — hosted checkout page (Stripe Checkout or merchant-of-record equivalent per G0 item 5) for the org-level plan. Webhook → entitlement service. No custom payment UI in v1; the provider's hosted page is fine and PCI-scope-free.
2. **Entitlement service** — small API alongside WS4's ingest (same deploy unit): issues org license keys on purchase webhook, validates keys (`POST /v1/license/validate`), tracks plan + status (active, past_due via dunning webhooks, canceled). Keys are org-scoped, not per-seat, in v1 — seat *counting* comes free from telemetry's per-user events; seat *enforcement* is deferred until there's evidence of abuse.
3. **Post-purchase delivery** — confirmation page + email with exactly one copy-paste block: the install one-liner with `DEWEY_LICENSE_KEY=<key>` inline, plus a link to the admin-onboarding flow (WS1) as the very next step. Purchase lands the buyer at the top of the WS1 funnel, not at a dashboard.
4. **CLI activation** — `install.sh` accepts `DEWEY_LICENSE_KEY` (env or flag): validates against the entitlement API, stores it in `~/.claude/dewey-license` (mode 600), and `dewey-telemetry.sh forward` (WS4) sends it as the auth bearer. No key → everything local still works; forwarding stays off and the Guide says why ("hosted features need a license — ask your admin for the key"). `/dewey license` subcommand shows status/activates later.
5. **Team distribution** — the admin's install message (WS1 stage 6) carries the org key, so seats activate by installing. One key per org, rotatable via a `POST /v1/license/rotate` admin call.
6. **Tests** — entitlement API contract tests; installer tests for key-present/key-absent/key-invalid paths (Layer 4 extensions, mocked endpoint); a no-network assertion that absence of a license never degrades local function.

### Deltas if G0 chooses Option A (fully gated)

Tarball downloads move behind signed URLs issued by the entitlement service; the refresh script must exchange the stored key for a short-lived download token each cycle (and must *not* brick the install when the entitlement check fails transiently — stale-but-working beats dead); WS2's public checksum publication changes to authenticated release manifests. ~1.5d extra, all in the two highest-risk files.

### Model tiers

| Piece | Model |
|---|---|
| Checkout integration + webhooks | **Sonnet** (provider SDKs are well-trodden; webhook idempotency is the only subtle part) |
| Entitlement service + API | **Sonnet build, strong-model review** — auth, key storage, and the validate endpoint are security surface |
| Installer/license integration | **Sonnet build, strong-model review** (touches install.sh — same rule as WS2) |
| Delivery email/page copy | **Sonnet draft, you approve** — it's the first thing a paying customer reads |
| Contract + installer tests | **Sonnet** |

Effort ≈ 3.5d (option B). Depends on: G0 items 4–5 decided; WS2's release machinery (the post-purchase one-liner should point at a pinned release); WS4's service skeleton (shared deploy unit).

## Schedule shape

Assuming roughly half-time attention:

- **Week 1:** WS1 phases 1–3 ∥ WS2 items 1–3. WS5 whenever Cowork is open.
- **Week 2:** WS1 phases 4–5 → WS3 ∥ WS2 items 4–5. G0 decisions settled mid-week.
- **Week 3:** WS4, then WS6 items 1–3 on its service skeleton.
- **Week 4:** WS6 items 4–6. Launch-readiness review at the end: all acceptance bars below.

## Launch-readiness checklist

- [ ] A stranger reaches a working demo in ≤5 minutes from one install command (WS1, timed dry-run)
- [ ] Install + refresh consume only tagged, checksum-verified releases by default; `docs/security.md` exists (WS2, clean-VM test)
- [ ] Eval harness green at the launch bar on a pinned model; wired into CI (WS3)
- [ ] The extension-loop digest demos from synthetic data; real ingest works end-to-end from one live event (WS4)
- [ ] Cowork rendering verified and documented; defects triaged (WS5)
- [ ] Test purchase → email → install → activated hosted features, end-to-end in ≤10 minutes with no human in the loop; a missing/invalid key never degrades local function (WS6, timed dry-run with a real test-mode payment)
- [ ] Full offline suite green (383+ — each WS adds tests)

## Not building (and why)

- **Multi-org** — consultant feature; each paying company is one org. Design ready in [multi-org-context.md](../decisions/multi-org-context.md) when demand shows.
- **Hosted stages 2–5** — the analyzer needs real traffic to be honest; UI is the most expensive thing to build for nobody. Gates in [hosted-dewey.md](hosted-dewey.md) stand.
- **Marketplace web UI** — first authors are fine in the PR flow.
- **Pricing/packaging/website** — business work, tracked at G0, not in this repo.
