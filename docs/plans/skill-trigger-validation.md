# Plan: Skill-trigger validation tooling

**Status:** Proposed, not yet started. Pick up when ready.
**Tracked in CLAUDE.md as todo #1 (Strategic / design).**
**Last updated:** 2026-05-06

## Context

Skills get auto-invoked by Claude based on the `description:` field. Bad descriptions = skills that never fire when they should. Today the only feedback loop is "user complains the skill didn't trigger." Goal: shift that feedback to author time, before users see broken triggering.

Originally framed as an "ambient nudge hook" (intercept user prompts and suggest matching skills). Reframed (CK, 2026-05-06) because the nudge approach duplicates what Claude Code already does via the `description:` field — meta-routing on top of routing is brittle. The leverage is upstream: help authors write descriptions that actually trigger correctly.

Three deliverables in increasing complexity. Ship in order; each is independently useful.

## Phase 1: `triggers:` schema + body-presence lint

Every SKILL.md gets a new optional frontmatter field:

```yaml
---
name: stakeholder-followup
description: Drafts a follow-up message after a sales call...
triggers:
  - "I just got off a call with Acme — write the recap"
  - "draft a follow-up for the Brian meeting"
  - "send a recap to Sarah after our intro"
---
```

For richer cases (multi-paragraph trigger rationale), allow a sibling `triggers.md` file in the skill directory.

### Lint (`tests/lib/check_triggers.py`, new Layer 15)

- Every in-tree skill has at least 3 triggers (warn if fewer; fail at 0 for plugins claiming canonical-quality).
- Each trigger is a non-empty string ≤ 200 chars.
- The skill's `description:` contains at least one substring overlap with each trigger (catches "the description doesn't actually include the user's words"). Heuristic — use lemma comparison or just bag-of-words intersection threshold.

### Demonstrator work

Add 3–5 triggers per existing skill (28 skills × ~3 = ~84 triggers). Mostly a couple of hours of writing.

### Files touched

- All 28 `plugins/*/skills/*/SKILL.md` (add `triggers:` blocks)
- `tests/lib/check_triggers.py` (new)
- `tests/run.sh` (new section)
- `docs/skill-triggers.md` (new — user-facing reference)
- Guide §3 Extend (when drafting an extension, ask for trigger examples and include them)

### Effort

~2 hours including the per-skill trigger backfill.

## Phase 2: description-quality lint

Promote the manual reviewer rubric in `docs/pr-checklist.md` into automated rules.

### Rules to enforce

- First sentence doesn't start with vague verbs (`helps`, `assists`, `supports`, `provides`)
- First sentence DOES start with an action verb (`Drafts`, `Analyzes`, `Generates`, `Pulls`, `Recaps`, `Identifies`, etc. — small allowlist)
- Description length 50–250 chars (Claude Code truncates ~250)
- Description contains at least one "Use when" clause or trigger language (e.g., the words "when the user", "when prepping", etc.)

### Lint (`tests/lib/check_description_quality.py`, extends Layer 15)

- Hard fail on length out of bounds.
- Hard fail on vague verbs in first sentence.
- Warn (don't fail) on missing "Use when" pattern — too many existing skills probably violate; soften to fail later.

### Existing-skill cleanup risk

Running Phase 2 retroactively against 28 skills will probably surface failures. Decide upfront: fix all 28 in this phase (probably 1–2 hours of editing), or grandfather existing skills and only enforce on new ones?

### Files touched

- All 28 SKILL.md files (potentially)
- `tests/lib/check_description_quality.py` (new)
- `tests/run.sh` (extends Layer 15)
- `docs/pr-checklist.md` (mark the manual rubric items as now lint-enforced)

### Effort

~1.5 hours assuming we fix existing skills inline.

## Phase 3: model-based eval harness (opt-in)

For each skill × each trigger, ask Claude (via Anthropic SDK) "given this user prompt and the list of installed skills, which would you invoke?" Assert the right skill is picked.

Same opt-in pattern as Layer 8:
- Gated by `DEWEY_EVAL_TRIGGERS=1` env var
- Requires `ANTHROPIC_API_KEY`
- Skips silently when env vars are unset
- Borrows test pattern from `anthropic-skills:skill-creator` (which already runs trigger evals)

### Cost discipline

- ~28 skills × ~3 triggers = ~84 prompts per full run
- Use Haiku, not Sonnet, for the routing call — ~$0.001 per prompt = ~$0.10 per full eval run
- Cache results keyed by (skill content hash, trigger string, model version) so re-runs without changes are free
- Document the cost in `docs/skill-triggers.md`

### Lint (`tests/lib/eval_triggers.py`, new Layer 16 or extends 15)

- Per (skill, trigger) pair: assert Claude picks the expected skill
- Aggregate report: skills with <80% trigger-match rate flagged for description rewrite
- Negative triggers (optional): assert specific *other* skills are NOT picked

### Caveats to document

- Results are model-version-dependent. Pin the model in the harness config; re-baseline when bumping.
- Not a guarantee of real-world routing — Claude's actual session has more context than our isolated eval prompt. Treat as a smoke test, not a guarantee.

### Files touched

- `tests/lib/eval_triggers.py` (new)
- `tests/run.sh` (new section, opt-in like Layer 8)
- `docs/skill-triggers.md` (cost + caveat section)
- `.github/workflows/trigger-eval.yml` (optional — schedule the eval on a slower cadence than drift-check, like monthly)

### Effort

~3 hours including caching, documentation, and a sanity-check pass over the actual routing accuracy of existing skills.

## Sequencing

| Phase | Effort | Ship value |
|---|---|---|
| 1 — triggers schema + body lint | 2h | Authors get a place to declare expected triggers; descriptions get checked against them mechanically |
| 2 — description quality lint | 1.5h | Bad descriptions fail at PR time; reviewers stop manually pattern-matching |
| 3 — model-based eval (opt-in) | 3h | Real evidence that triggers fire when expected; costs API credits |

Phase 1 alone is meaningful. Phase 2 is mechanical extension of Phase 1. Phase 3 is the real validation but the most expensive (in build time + ongoing API cost).

**Recommendation:** ship 1 + 2 in one chunk (~3.5 hours, no API credits), evaluate value, then decide on 3.

## Open questions

1. **Minimum trigger count.** Three feels like a sensible floor — fewer = author hasn't actually thought about it. Worth fail vs warn?
2. **Negative triggers.** Are `should-not-fire` examples worth the spec complexity? My read: no for v1, add later if the eval shows a lot of false positives in skill picking.
3. **Existing-skill grandfathering.** Phase 2 may surface description failures across the 28 in-tree skills. Fix all in this work or grandfather and only enforce going forward? My read: fix all — cleanup is short and tests-passing is a virtue.
4. **Eval harness model.** Haiku for cost, but does Haiku's routing actually match Sonnet/Opus's? We may need to eval with the same model the user runs. Worth testing both before committing.
5. **Where does the cost go.** If we run Phase 3 in CI on every PR, that's ~$0.10/PR — small but not free. If we run it nightly or on a schedule, that's bounded. Recommendation: PR-only when SKILL.md files change, plus a monthly drift-eval workflow.

## Relationship to `docs/pr-checklist.md`

The PR checklist currently lists manual review rules. After Phases 1 + 2, most of those rules are now automated. The doc should be refactored from "what reviewers should manually check" to "what the lint already enforces, plus the judgment calls reviewers still need to make" — the residual is mostly *content quality* (does the skill actually do what the description says?), which can't be linted.

## Decision points to settle before building

- Phases 1+2 only, or all three?
- Fail or warn on Phase 1 minimum-trigger count?
- Fix existing-skill descriptions inline in Phase 2, or grandfather?
- Phase 3 eval cadence — PR-only, scheduled, both?

## Related

- `docs/pr-checklist.md` — current manual rubric; gets refactored after Phase 2
- `tests/run.sh` Layer 8 — opt-in pattern Phase 3 borrows
- Anthropic's `skill-creator` skill — already does trigger evals; worth borrowing pattern
- CLAUDE.md todo #1 — entry that points here
