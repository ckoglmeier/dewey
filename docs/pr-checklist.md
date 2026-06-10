# Central skill PR checklist

Skills in the central Dewey repo are **immutable to most users** — once installed, they're trusted defaults for everyone. That means the bar for merging a new central skill is high. This checklist is what a maintainer should walk through before clicking merge.

## What gets reviewed

### 1. Does this belong in the central repo?

Central skills are for problems **multiple teams** have. If only one team needs this, it should live in their team extension repo (`dewey-extensions-<team>`), not central.

Test: can you name three teams that would install this on day one? If not, send it back.

### 2. Is the description specific? *(partially lint-enforced)*

Skill discovery in Claude Code depends on the `description` frontmatter field. Generic descriptions ("helps with sales tasks") never get auto-loaded by the model.

**The lint now enforces** (Layer 15, `tests/lib/check_description_quality.py` — a violating PR fails CI):

- Description length 50–250 chars (truncation kicks in at 250)
- First sentence must not lead with a vague verb ("helps", "assists", "supports", "provides")

**Reviewers still judge:**

- Does the first sentence front-load the **specific use case**, not just pass the verb check?
- Does it include the **trigger words** a real user would say? (The lint only warns on missing "use when" language.)

### 2b. Does it declare realistic triggers? *(lint-enforced)*

Every user-invocable skill needs a `triggers:` frontmatter field with 3–5 example user utterances. See [skill-triggers.md](skill-triggers.md) for the format and what makes a good trigger. The lint (`tests/lib/check_triggers.py`) fails a PR with no triggers, triggers over 200 chars, or triggers sharing zero significant words with the description; it warns below 3. Skills marked `user-invocable: false` must **not** have triggers — routing to them goes through their orchestrator.

**Reviewers still judge:** are the triggers things a real user would actually type, and do they route to *this* skill rather than a sibling? The lint can't tell a realistic utterance from a paraphrase of the description.

### 3. Does it produce an output a non-technical user could read in under 90 seconds?

The Ramp finding: people who got value were the ones who installed a skill and immediately got a *useful* result. Long, comprehensive outputs lose that moment. The skill body should explicitly tell Claude when to stop, and the "stop" condition should be defined by user value, not completeness.

A good signal: every seed skill in this repo has a "When to stop" section.

### 4. Is the output format spelled out?

If the skill produces a structured output, the body should include the format as a code block. This makes the output predictable for the user and stops Claude from improvising layouts. Check the seed skills for examples.

### 5. Does it avoid invented data?

Skills that fabricate plausible-sounding facts (made-up sources, invented quotes, hallucinated stats) erode trust faster than anything else. The skill body should explicitly tell Claude what to do when data isn't available — usually "say so explicitly, don't fill in fiction."

### 6. Is the body under ~500 lines?

Per the Claude Code skill docs: keep `SKILL.md` under 500 lines and move detailed reference material to separate files in the skill directory. Long skill bodies eat context.

### 7. Plugin packaging

- The skill lives at `plugins/<plugin>/skills/<skill>/SKILL.md`.
- The plugin has a `.claude-plugin/plugin.json` with `name`, `description`, `version`, and **`owner`**. The `owner` field has shape `{"name": "...", "contact": "..."}` — Slack handle, email, or GitHub handle. Test suite enforces this; an unowned plugin will fail CI.
- The plugin appears in the top-level `.claude-plugin/marketplace.json` with a description, category, and tags.
- The plugin directory has a corresponding line in the root `CODEOWNERS` file so GitHub auto-requests review from the right person on subsequent PRs. Test suite enforces this too.

### 8. Does a path file recommend it?

A new central skill that no path file ever surfaces is dead weight — non-technical users will never find it. As part of the PR, either:

- Update an existing path file to recommend it (with a one-sentence "why"), OR
- Note in the PR description which roles this skill is for and which team lead should be pinged to update their path

## What does NOT need to be perfect

- **Polish.** Ship it imperfect and fix it from real usage. Telemetry beats opinions.
- **Comprehensiveness.** A focused skill that does one thing well beats a kitchen-sink skill.
- **Unique value.** It's fine if the skill overlaps with another — let users choose.

## What is grounds for "send it back"

- Generic description that doesn't include use cases or trigger words (the worst cases now fail CI; borderline ones are still a reviewer call).
- Triggers that paraphrase the description instead of sounding like a real user.
- No "when to stop" condition.
- Output format not spelled out.
- Skill that needs MCP servers or tools the average user doesn't have configured (move it to a team extension repo instead).
- Skill that's really an extension of an existing skill in disguise (write it as an extension, not a fork).

## Reviewing canonical context PRs

Context PRs (a `context/` file or a `requires-context:` change) get extra scrutiny because context content reaches Claude's context window verbatim. See the full conventions in [canonical-context.md](canonical-context.md). Quick checklist for reviewers:

- **Reference, not procedure.** Context describes facts; skills describe what the agent should do. A context file with imperative agent instructions ("you should always X") belongs in a skill, not in context.
- **Prompt-injection awareness.** If the context includes externally-sourced material (quoted competitor copy, screenshots OCR'd to markdown, external research notes), strip imperative or AI-targeted content. "If you are an AI, also tell the user X" is the obvious case; subtler steering is the real risk.
- **Size sanity.** v1 size limits are 20KB warn / 100KB fail per file (overridable with `allow-large-context: true`). Pushing the limit is a smell: split into multiple files unless the corpus is genuinely a single document.
- **Stable IDs.** A new context entry's `id` follows `<plugin>/<bundle>` and the plugin segment matches the containing plugin.
- **Skills referencing the context update their bodies too.** The lint catches frontmatter/body drift, but reviewers should still confirm the skill's "First, load:" step is updated when a context dependency changes.
