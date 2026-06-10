# Plan: Hosted Dewey — sequencing the product layer

**Status:** Proposed. Nothing here blocks or drives this repo's roadmap except the explicitly-marked local hooks.
**Date:** 2026-06-10

## What hosted Dewey is

A separate hosted product that consumes the data pipe the local convention already produces. Local Dewey deliberately only **captures and forwards** — no analysis, no recommendations, no PRs from telemetry. Everything that aggregates across users or orgs lives here.

The bucket, restated from the roadmap: telemetry aggregator + analyzer, MCP for native push (`propose_skill` etc.), publisher mode, marketplace web UI, staged rollouts, multi-owner governance, chat distribution, org-managed scheduled distribution.

## What the local side already provides

| Local contract | Where | Hosted consumer |
|---|---|---|
| JSONL event stream with three-tier opt-out and body-stripping | `dewey-telemetry.sh`, `docs/extension-telemetry.md` | Aggregator ingest |
| Forwarding endpoint contract (`DEWEY_TELEMETRY_ENDPOINT`) | documented, unimplemented sender | The ingest API's shape |
| PR-based propose flow with CODEOWNERS routing | `dewey-propose.sh` | Publisher mode's review queue maps onto PRs first |
| Stable IDs for skills (`plugin/skill`) and context (`plugin/bundle`) | marketplace + plugin.json conventions | Every hosted entity key |
| `org` field on events | **not yet** — Phase 4 of [multi-org-context.md](../decisions/multi-org-context.md) | Org data segregation; cheap now, painful migration later |

## Sequencing principle

Ship the smallest thing that closes the loop the local repo cannot: *N users' extension patterns → one canonical improvement*. That's the aggregator. Everything else (UI, governance, rollouts) decorates that loop. Defer anything Anthropic might ship natively (chat distribution — see `docs/research/claude-ai-distribution.md`: watch [anthropics/claude-code#28729](https://github.com/anthropics/claude-code/issues/28729), build nothing speculatively).

## Stages

### Stage 1 — Ingest + digest (the MVP)

A small service: authenticated POST endpoint matching the `DEWEY_TELEMETRY_ENDPOINT` contract, append-only event store keyed by (org, plugin, skill, event), and a **weekly maintainer digest** — "12 users extended `weekly-status-update`; 9 of those added a Slack lookup" — delivered as email/Slack, not a UI. Plus the local sender: a `forward` subcommand in `dewey-telemetry.sh` (batched, fails silent, respects all opt-outs).

*Closes the loop manually: maintainer reads digest, writes the canonical PR themselves.*

### Stage 2 — Analyzer + proposed canonicals

Pattern detection over the store (clustering extension `additions` by similarity) and auto-drafted PRs against the org's repo — the hosted side uses the same propose flow locally shipped, so review/CODEOWNERS governance is inherited, not rebuilt. Cost discipline: batch nightly on a small model; nothing latency-sensitive.

### Stage 3 — MCP for native push

An MCP server exposing `propose_skill`, `propose_skill_update`, `propose_context`, `search_marketplace`. Replaces `gh` plumbing for conversational authoring from Code/Cowork/Codex. This is also the first piece that makes the hosted layer *user-facing* rather than maintainer-facing.

### Stage 4 — Publisher mode

Embedded Claude conversation for skill/context owners: review queue (now fed by stages 2–3), usage data per skill, extension-pattern browser, accept/reject proposals, version history. The conversation design should reuse the admin-onboarding skill's stage structure ([admin-onboarding.md](admin-onboarding.md)) — it's the same persona one step later in their lifecycle.

### Stage 5 — Marketplace UI + staged rollouts + governance

Web UI for browsing/authoring without a repo clone; canary-percentage rollouts of canonical updates (requires the refresh script to consult a hosted manifest — a small, explicitly-flagged local hook); multi-owner required-review for high-impact changes; deprecation flows.

### Stage 6 — Distribution expansions

Chat distribution and org-managed scheduled distribution (one team lead schedules, many users receive, output lands in a per-team channel). Both blocked on external surface area today; sequenced last on purpose.

## Local hooks needed (the only items that touch this repo)

1. **`org` field on telemetry events** — multi-org Phase 4. Do before any forwarding exists.
2. **`dewey-telemetry.sh forward`** — Stage 1. Batched sender honoring the documented contract.
3. **Refresh-manifest consultation** — Stage 5 only. Do not build early.

## Build plan (model tiers)

| Stage | Model | Effort | Notes |
|---|---|---|---|
| 1 ingest + digest | **Sonnet** for service scaffolding + local sender; **strong-model review** on the ingest API contract (it's the one interface every later stage depends on — get the event schema right once) | ~2 days | |
| 2 analyzer | **Sonnet** pipeline; clustering prompts evaluated with a small judge-panel workflow before trusting output | ~2 days | Haiku for the nightly batch runtime itself |
| 3 MCP server | **Sonnet** (MCP SDK is well-trodden); strong-model review on auth | ~1.5 days | |
| 4 publisher mode | **Strong model designs the conversation**, Sonnet implements | ~3 days | Same split as admin-onboarding |
| 5 UI + rollouts + governance | Sonnet throughout; strong-model review on the rollout-manifest local hook | XL — break down when reached | |
| 6 distribution | Blocked on externals — no estimate | — | |

## Decision gates

- **Before Stage 1:** is there at least one org (besides CK) forwarding events? If not, the digest has one reader and the local analytics file already serves them. Don't build a service for an audience of one.
- **Before Stage 3:** has Stage 2 produced ≥1 accepted canonical PR? If maintainers reject the analyzer's proposals, fix that before widening the funnel.
- **Before Stage 5:** does any adopting org have non-technical authors asking for it? UI is the most expensive stage and the easiest to build for nobody.
