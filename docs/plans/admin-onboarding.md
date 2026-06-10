# Plan: Smart admin onboarding

**Status:** Proposed, not started.
**Date:** 2026-06-10
**Tracked in CLAUDE.md (Strategic / design).**

## Problem

"Adopting Dewey for your company" is currently a 6-step engineer's checklist in the README: fork the repo, edit marketplace.json, replace seed skills, register CODEOWNERS, and so on. The person who actually owns "what skills do my teams use" is almost never an engineer — it's an ops or RevOps lead who will not clone a repo. The gap between "curious admin" and "first three users getting value" is where adoption dies.

## Decision: separate skill, not a Guide subcommand

The flow ships as its own in-tree skill — **`dewey-admin-setup`** in a new `admin` plugin — rather than a `/dewey admin-setup` subcommand.

Rationale:
- The Guide is already ~550 lines and is the product's most-read surface; a full onboarding conversation would roughly double it and degrade routing for the 99% of invocations that are consumer flows.
- Onboarding runs ~once per org. A separate skill can be installed for the setup week and removed after; the Guide stays permanently lean.
- The Guide still owns discovery: its menu and its "no marketplace found" error path both point to admin-setup ("Setting Dewey up for your company? Install and run `dewey-admin-setup`."). Entry stays unified; implementation doesn't.

## The flow

Six conversational stages. Each ends with a concrete artifact the admin can see, and the skill always confirms before writing anything (same trust contract as the Guide).

1. **Discover the org.** Company name, industry, primary teams (Sales, CS, Ops, Eng…), 2–3 key roles per team, and which team feels the most pain today. Output: an org-profile block reused by every later stage.
2. **Seed canonical context.** Interactive prompts build the first context bundles — company identity, ICP, brand voice, top-of-funnel positioning — from templates tuned by stage-1 answers. Output goes through the existing propose flow (`dewey-propose.sh`) as PRs against the org's fork, so review and CODEOWNERS routing work from day one.
3. **Draft initial path files.** One per role from stage 1, generated from a starter-template library and tuned by the discovery answers. Again via propose.
4. **Suggest plugins.** Map stage-1 teams to in-tree plugins (analysts → research-assistant, sales → sales-enablement…) and walk through keeping/dropping seed plugins. External entries get registered with the Layer 8 / drift-check safety net called out explicitly.
5. **Demonstrate the loop end-to-end.** Install one skill against the seeded context and run it live. **First demo: `weekly-status-update` for the admin themselves** — fast, concrete, zero external integrations. Then point at `competitive-analysis` as the follow-up that proves canonical context (it reads the positioning bundle seeded in stage 2).
6. **Invite the first wave.** Generate a copy-paste install message for the admin's first 3 users, pointing at their fork's install one-liner and the role paths from stage 3.

**Prerequisite gate (stage 0):** the skill checks for a forked repo + `gh` auth before stage 2, and if absent walks the admin through the GitHub fork flow (or hands a one-paragraph ask for whoever owns their GitHub org). This is the one unavoidably technical moment; isolating it at the start, with an escape hatch, beats hitting it mid-conversation.

## Deliverables

| Artifact | Notes |
|---|---|
| `plugins/admin/skills/dewey-admin-setup/SKILL.md` | The flow. Same conventions as the Guide: confirm-before-acting, surfaces-aware, triggers + lint-compliant description. |
| `plugins/admin/templates/paths/*.md` | Starter path-file templates: sales-ae, cs-manager, ops-analyst, eng-lead, exec. Parameterized by org profile. |
| `plugins/admin/templates/context/*.md` | Starter context bundles: company-identity, icp, brand-voice, positioning. |
| Guide edits | Menu line + "no marketplace" error path pointing at admin-setup. |
| `docs/admin-onboarding.md` | Short user-facing doc replacing the README checklist; README section shrinks to a pointer. |
| Layer additions | Lint: templates parse, admin plugin passes Layers 2/5/11/15 like any other plugin. |

## Build plan

| Phase | What | Model | Effort |
|---|---|---|---|
| 1 | Skill body: stages 0–1 + 5–6 (discovery, demo, invite — no propose dependency) | **Sonnet drafts, strong-model review** — this is the org's first impression of Dewey; conversation design quality is the product | ~3h |
| 2 | Template library (5 path templates, 4 context templates) | **Sonnet** (content judgment, well-bounded) | ~2h |
| 3 | Stages 2–4 (context seeding, path drafting, plugin registration — all through the propose flow) | **Sonnet**; strong-model review on the propose-integration edges (failure modes: no fork, no gh, PR rejected) | ~3h |
| 4 | Guide pointers, docs, README shrink, lint wiring | **Haiku** (exact-spec edits) + one Sonnet pass on the user-facing doc | ~1.5h |
| 5 | Dry-run eval: a Sonnet agent role-plays a non-technical RevOps admin through the whole flow against a scratch fork; a second agent (author-blind) grades friction points | **Sonnet ×2** | ~1.5h |

Total ≈ 11h. Phases 1+2 are demoable alone (discovery → demo → invite, with templates hand-installed); 3 makes it real.

## Open questions

1. **Hosted handoff.** Once hosted Dewey exists, this same flow becomes its "publisher mode" front door ([hosted-dewey.md](hosted-dewey.md)). Keep the stage structure host-agnostic so the conversation ports; only the write-targets change (PR today, API later).
2. **Fork-less trial.** Should stage 5's demo work *before* any fork exists (against the reference marketplace), so an admin gets value in minute five and forks afterward? Leaning yes — re-evaluate when building phase 1.
3. **Multi-org interaction.** An admin onboarding their company while already a multi-org user is fine — the fork becomes one org entry per [multi-org-context.md](../decisions/multi-org-context.md). No coupling needed in v1.
