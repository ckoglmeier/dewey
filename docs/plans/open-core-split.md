# Plan: Open-core split — public convention, private per-seat SaaS

**Status:** Phase 1 DONE (steps 1.1–1.3 complete; step 1.4 conformance test in dewey-cloud is the remaining item). Phase 2 and 3 not yet started.
**Amends:** [hosted-dewey.md](hosted-dewey.md) G0 decision #2 (pricing: org-flat → **per-seat recurring**) and the WS4/WS6 repo layout in [go-to-market.md](go-to-market.md).

## Context

PR #4 carried both products in one branch: the open convention *and* the commercial hosted service (previously under `hosted/`). The commercial code was extracted to `ckoglmeier/dewey-cloud` (private) before #4 merges. The architectural boundary is clean — the only coupling is the HTTP contract in `docs/hosted-api.md`; this plan makes the repo layout match it, then upgrades the commercial side from org-flat to per-seat recurring.

## Target state

| | `ckoglmeier/dewey` (public, MIT) | `ckoglmeier/dewey-cloud` (private, commercial) |
|---|---|---|
| Contents | Installer, Guide, 8 plugins, templates, release machinery, eval harness, CLI licensing **client** (`DEWEY_LICENSE_KEY`, `forward`, Guide §12), `docs/hosted-api.md` (the contract) | `dewey_hosted/` service, dewey-cloud RUNBOOK, purchase/checkout templates, unit suite, billing + seat logic, future stages 2–5 |
| Tests | Suite incl. a **contract-mock** Layer 16 (stdlib mock server implementing `docs/hosted-api.md`; asserts the CLI client speaks the contract) | Unit suite + a **contract-conformance** job that runs the *same* contract cases against the real service |
| The license a buyer needs | none — everything here is free, forever | required for forwarding, digest, and all hosted features |

The contract doc is the hinge: both repos test against it, so drift breaks CI on whichever side moved.

## Phase 1 — Extraction (before #4 merges)

| Step | What | Model | Effort |
|---|---|---|---|
| 1.1 | Create private `dewey-cloud` repo; move `hosted/` there with a **fresh history** (no need to preserve commits — copy at HEAD, initial commit). Add its own README, CI (unit suite + lint), LICENSE (proprietary/BUSL — CK to choose) | me + **Haiku** for mechanical file moves | ~1h |
| 1.2 | Write `docs/hosted-api.md` in the public repo: the full wire contract — `/v1/events` (bearer auth, JSONL, org-from-license, 1MB cap, status semantics), `/v1/license/validate` (boolean-only), key format, error codes, and the telemetry event schema incl. the org field. This is the spec both sides test against | **Sonnet draft, strong-model review** — it's the interface both products depend on | ~1.5h |
| 1.3 | Strip `hosted/` from `feat/gtm-build`; replace Layer 16 with contract-mock tests (stdlib mock implementing the doc; existing layer-12 mock-server pattern reusable); update `.github/workflows/test.yml` (drop the hosted-unittest step); sweep docs (`go-to-market.md`, `hosted-dewey.md`, CLAUDE.md, security.md) for `hosted/` path references → point at the contract doc + "the hosted service is a separate commercial product" | **Sonnet** | ~2h |
| 1.4 | In `dewey-cloud`: port the 54-test suite, add a contract-conformance test that loads the public repo's contract cases (vendored copy, refreshed by a sync script) against the real service | **Sonnet** | ~1h |

**Gate 1:** public suite fully green with no `hosted/` directory and no commercial references; `dewey-cloud` CI green; `git log --all -- hosted/` on the public branch shows the code never reached main.

## Phase 2 — Merge + first release

| Step | What | Model | Effort |
|---|---|---|---|
| 2.1 | Merge the slimmed #4 | human click | — |
| 2.2 | Cut the first public release per RELEASING.md (tag, build assets, `gh release create`) so the pinned-install default has a real target | me | ~0.5h |

**Gate 2:** clean-machine install from the published release verifies checksum and lands a working Guide.

## Phase 3 — Per-seat recurring (in `dewey-cloud`, plus one public contract rev)

Today's model is org-flat: one org key, seats counted only in synthetic data. Per-seat recurring needs four things:

| Step | What | Where | Model | Effort |
|---|---|---|---|---|
| 3.1 | **Pseudonymous install ID in telemetry events.** A random `install_id` (generated once at install, stored `~/.claude/dewey-install-id`, no hostname/username derivation) added to emitted events. Contract rev v1.1 in `docs/hosted-api.md`; same three-tier opt-out applies; documented in security.md. This is the public repo's only Phase-3 change | public | **Sonnet build, strong-model review** (privacy surface) | ~1.5h |
| 3.2 | **Schema + lifecycle**: `seats`, `subscription_id` columns on orgs; handle `customer.subscription.updated` (quantity changes); trial status if the provider sends it | dewey-cloud | **Sonnet** | ~1.5h |
| 3.3 | **Seat counting + true-up**: distinct `install_id` per org per billing period; a `report-seats` job that emits the count for the operator (v1: prints/logs the true-up number; auto-sync to the provider's subscription quantity is v1.1, after a real account exists) | dewey-cloud | **Sonnet** | ~1.5h |
| 3.4 | **Enforcement policy = true-up, not lockout** (decision): the org key stays shared; seats are counted and billed, never blocked. Rationale: lockout punishes the org's 21st user for the admin's billing lag and adds a hard dependency on service uptime to local-adjacent features; true-up preserves the open-core trust story. Revisit only on abuse evidence. Documented in dewey-cloud README + checkout-page copy | dewey-cloud | doc only | ~0.5h |

**Gate 3:** e2e on the dev service: two simulated installs under one org → digest shows 2 seats → `report-seats` emits 2 → `subscription.updated` with quantity 2 recorded. Eval-grade adversarial pass on the install-ID privacy properties (no PII derivable, opt-out honored).

## What does NOT change

- The CLI client behavior and the open-core guarantee (no license ever degrades local function) — already test-asserted, stays in the public repo.
- The security posture from the adversarial review — all four fixes ride along into `dewey-cloud`.
- No live payments until a human connects the provider account (unchanged RUNBOOK gate, now in the private repo).

## Open questions for CK

1. **`dewey-cloud` license**: proprietary all-rights-reserved vs. BUSL/fair-source? (Affects whether design partners can self-host.)
2. **Price point + trial length** for the per-seat plan — business call, blocks checkout-page copy only.
3. Repo name — `dewey-cloud` assumed; say the word if you want different.

## Sequencing summary

Phase 1 (≈5.5h) → Gate 1 → merge + release (Phase 2) → Phase 3 (≈5h) in the private repo. Phases 1–2 unblock the public launch; Phase 3 unblocks charging per seat. Nothing in Phase 3 blocks merging — org-flat keys keep working during the transition.
