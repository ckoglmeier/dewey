# Decision: Multi-organization context

**Status:** PROPOSED — design settled, build not started.
**Date:** 2026-06-10
**Tracked in CLAUDE.md (Strategic / design).**

## Problem

Dewey assumes one canonical org: one marketplace, one set of skills, one set of canonical context. Real users — consultants, board members, portfolio operators, anyone with a personal practice alongside a company role — operate across several orgs at once. Each org has its own positioning, brand voice, ICP, strategy docs, and customer accounts. The same skill (`competitive-analysis`) must resolve to *different* canonical context depending on which org the user is acting for right now. Today there is no way to tell Dewey which org is active, and skill bodies hardcode a single cache path (`~/.claude/dewey/...`).

**Who this is for:** the consultant / portfolio-operator / multi-hat founder. An enterprise admin running Dewey for one company never hits this — nothing here may complicate the single-org path. Single-org must remain the zero-configuration default.

## Options considered

| | Shape | Verdict |
|---|---|---|
| A | **Org-tagged plugins/context** — `org:` field on each plugin or context entry; one shared cache; Guide filters by active org | Rejected. Mixes orgs in one namespace: collisions (two orgs both ship `competitive-intelligence`), and an org's repo must be edited to coexist with others — orgs shouldn't know about each other. |
| B | **Multi-Dewey installs** — one cache per org, each its own marketplace registration | Half the answer. Matches distribution reality (each adopting org forks the repo, so a multi-org user naturally has N upstream repos) but says nothing about which org a skill reads *right now*. |
| C | **Active-org context bundle** — a single "current org" pointer; resolution reads the active org's bundle | The other half. Resolution mechanism, but needs B's storage answer underneath it. |
| D | **Hybrid composition** — personal Dewey as base layer, org Deweys layered via the extension convention | Rejected as the primary mechanism. Layering answers "how do I customize an org's skills" (the existing three-tier model already does) — not "which org am I acting for." Composition stays available *within* whichever org is active. |

## Decision: B for storage, C for resolution

**One cache per org; one active-org pointer; resolution follows the pointer.**

### Storage (shape B)

```
~/.claude/dewey/                  ← the DEFAULT org's cache (unchanged — back-compat)
~/.claude/dewey-orgs/<org-id>/    ← each additional org's cache (same layout inside)
~/.claude/dewey-orgs.json         ← registry: org-id → { repo, ref, cache_path, label }
```

- A single-org user never sees `dewey-orgs/` — their world is byte-identical to today.
- `install.sh` gains `DEWEY_ORG=<id>`: when set, installs to `~/.claude/dewey-orgs/<id>/`, registers the marketplace under a namespaced name (`dewey-<id>`), and appends to the registry. When unset, behavior is exactly current.
- Each org's cache refreshes independently (the existing refresh script, parameterized by cache path).

### Resolution (shape C)

- **Active-org pointer:** `~/.claude/dewey-active-org` (one line: the org id; absent = default org).
- **Persistent default, session override.** The pointer file is the durable default; `DEWEY_ORG` in the environment overrides it for one session; `/dewey switch <org>` updates the pointer (with confirm). Rationale: a consultant works in blocks — "this week is mostly Task Engineering" — so a sticky default with a cheap override beats per-session ceremony.
- **Skill context loading becomes a resolution order**, replacing today's hardcoded path. The convention (documented in `canonical-context.md`, enforced by an updated Layer 14 lint) becomes:
  1. `$DEWEY_ORG` env if set → that org's cache
  2. else the pointer file's org → that org's cache
  3. else `~/.claude/dewey/` (default org, current behavior)
- The Guide surfaces the active org in every flow header ("Acting for: **task-engineering**") so a wrong-org mistake is visible before output is generated, not after.

### Team extensions

Team is a **sub-concept of org**: `dewey-extensions-<team>` repos belong to exactly one org and only compose when that org is active. The personal tier (`~/.claude/skills/`) stays orthogonal — always active regardless of org, because personal extensions are about *you*, not the org.

### Telemetry

Every event gains an `org` field (the resolved org id at emission time). The forwarding contract (`DEWEY_TELEMETRY_ENDPOINT`) is unchanged in shape; the future hosted aggregator keys segregation on this field. See [hosted-dewey.md](../plans/hosted-dewey.md) — org segregation is a hosted-side requirement that costs one field locally if we add it now, and a migration if we don't.

## What this deliberately does not do

- **No cross-org composition.** A skill never reads two orgs' context in one invocation. If a real use case emerges (e.g. a portfolio review spanning holdings), it's a new decision, not a default.
- **No org-aware marketplace UI changes.** Claude Code's plugin browser shows N marketplaces; that's fine for v1.
- **No automatic org inference** (from cwd, git remote, calendar). Tempting, error-prone, and wrong-org context failures are silent quality failures. Explicit beats clever here; revisit only with evidence that switching friction is real.

## Build plan

Each phase is independently shippable. Model = least powerful that can build it reliably; "review" = a stronger model checks the diff.

| Phase | What | Files | Model | Effort |
|---|---|---|---|---|
| 1 | Registry + pointer + `/dewey switch` flow + "Acting for" header in Guide flows | `guide/SKILL.md`, `docs/multi-org.md` (new) | **Sonnet** (Guide prose + conventions; opus review of the switch-flow wording) | ~2h |
| 2 | `install.sh` org namespacing (`DEWEY_ORG`), registry writes, refresh parameterization | `install.sh`, `tests/layers/layer-04-install.sh`, new layer-16 multi-org tests | **Sonnet build, strong-model review** — installer changes are the highest-blast-radius code in the repo | ~3h |
| 3 | Context resolution order: update the loading convention in every skill body that Reads context, plus the Layer 14 lint to enforce the new path list | `plugins/*/skills/*/SKILL.md` (mechanical, exact-spec edits — **Haiku**), `tests/layers/layer-14-context.sh` + lint (**Sonnet**) | Haiku + Sonnet | ~2h |
| 4 | Telemetry `org` field + docs | `dewey-telemetry.sh`, `docs/extension-telemetry.md`, layer-12 tests | **Haiku** (exact spec: add one field, three test assertions) | ~1h |

Total ≈ 8h. Phases 1+2 deliver visible value alone (switchable installs); 3 is the moment the same skill actually reads different context per org; 4 is hosted-readiness.

## Revisit conditions

- Claude Code ships native multi-marketplace context scoping → reassess whether the pointer file should defer to it.
- An adopting org wants org-of-orgs (holding company with subsidiaries) → the registry is flat today; nesting is a new decision.
- Evidence of frequent wrong-org output despite the header → reopen automatic inference.
