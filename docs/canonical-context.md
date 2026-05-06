# Canonical context — author's reference

Skills tell Claude *how to do something*. Context tells Claude *what your company believes* — battlecards, brand voice, product strategy, ICP definitions. Classroom plugins can ship context alongside skills so it's published, owned, versioned, and extensible just like a skill.

This is the user-facing reference. The full design rationale lives in [canonical-context-design.md](canonical-context-design.md).

## Where context lives in a plugin

A plugin can have skills, context, both, or just context. Layout:

```
plugins/<plugin>/
├── .claude-plugin/plugin.json        # declares the context bundles
├── skills/                            # optional
│   └── <skill>/SKILL.md
└── context/                           # optional
    └── <bundle>/                      # one bundle = one or more files
        └── <bundle>.md
```

A "bundle" is a logical unit of canonical context — usually a single markdown file, occasionally a directory of related files (e.g. `battlecards/` containing one file per competitor).

## Declaring a context bundle in plugin.json

```json
{
  "name": "competitive-intelligence",
  "description": "...",
  "version": "0.1.0",
  "author": { "name": "CK", "contact": "@ck" },
  "surfaces": ["claude-code", "cowork", "codex", "chat"],
  "context": [
    {
      "id": "competitive-intelligence/positioning",
      "path": "context/positioning/positioning.md",
      "title": "Positioning reference",
      "description": "Canonical positioning, differentiators, non-fit segments, banned phrases."
    }
  ]
}
```

Required fields per entry: `id`, `path`, `title`. Optional: `description`, `surfaces` (defaults to the plugin's surfaces), `allow-large-context: true` (overrides the size lint — use sparingly).

The `id` follows `<plugin>/<bundle>` and the `<plugin>` segment must match the containing plugin. This makes `id` a stable global handle: even if you rearrange the on-disk path later, skills referencing the ID continue to resolve.

## Declaring a context dependency in a skill

In SKILL.md frontmatter:

```yaml
---
name: competitive-analysis
description: ...
requires-context:
  - competitive-intelligence/positioning
---
```

Use the **block form** — one `- id` per line. Inline `[a, b]` form is rejected by the lint.

Then in the skill body, include a "First, load:" section that references the same ID(s):

```markdown
## First, load context

- Stable ID: `competitive-intelligence/positioning`
- Look for it at one of these paths (read whichever exists):
  - `~/.claude/classroom/plugins/competitive-intelligence/context/positioning/positioning.md` (Claude Code or Cowork)
  - `~/.codex/context/competitive-intelligence/positioning/positioning.md` (standalone Codex)

Read the file in full. If neither path exists, stop and tell the user the plugin appears to be incomplete.
```

The lint enforces that every declared `requires-context:` ID literally appears in the skill body. This catches drift — you can't rename or remove a dependency in frontmatter without also updating the load step.

## Why two paths?

Cowork shares `~/.claude/` with Claude Code, so the first path covers both. Standalone Codex uses `~/.codex/` and Classroom's sync mirrors context bundles to `~/.codex/context/<plugin>/`. Skills should reference both paths so they work in either environment.

## Extending canonical context

Same convention as skill extensions, applied to context. Create a SKILL.md (yes, the same file shape) with `extends-context:` instead of `extends:`:

```markdown
---
name: brand-voice-sf-team
description: SF team's regional brand voice additions
extends-context: brand/voice
---

# SF Team voice extensions

Add these examples on top of canonical brand voice:

- "Howdy, partner" is fine for casual outbound but never for board comms
- ...
```

The skill's body should layer on top of canonical, not replace it. Loading order at runtime is canonical first, then extensions sorted by plugin name and extension name. v1 is append-only — no override semantics.

## Size limits

To keep context cheap and skill prompts focused:

- Each context file: ≤ 20KB warns, ≤ 100KB fails the lint unless the entry has `allow-large-context: true`.
- Total declared context for a single skill: ≤ 80KB warns, ≤ 300KB fails unless every involved entry sets `allow-large-context: true`.

If you need a longer doc, split it. A `strategy/` bundle could have `north-stars.md`, `roadmap-themes.md`, and `non-goals.md` as separate files. Skills can declare any subset.

If the corpus is genuinely large reference material that's *only* loaded on demand (e.g. an FAQ corpus that's grep-searched), set `allow-large-context: true` on the entry. Use this sparingly — it disables the size lint for that bundle but doesn't change runtime behavior.

## Surface compatibility

The lint enforces that a skill's surfaces ⊆ each required context's surfaces. So if your skill claims `chat` support, every context bundle it requires must also support `chat`. Practically this means context bundles should default to all four surfaces (Markdown is universal); the only reason to scope context narrower is if it ships data only meaningful in a specific runtime.

## Proposing context changes

`/classroom propose` has three context sub-flows:

- `propose new-context` — add a new context bundle to an existing plugin
- `propose update-context <id>` — update an existing canonical context bundle
- `propose promote-context-extension` — turn a local `extends-context:` extension into a canonical update or new sibling

The Guide drafts the change, runs `tests/run.sh` against the working tree, opens a PR via `gh`. Same flow as skill proposals — see [proposing-changes.md](proposing-changes.md).

## Content safety

Context files are markdown, but they still reach Claude's context window as prompt material. Treat them as reference, not procedure:

- **Don't put imperative agent instructions in context files.** Battlecards describe what's true about the world, not what the agent should do. Skills tell the agent what to do.
- **Be careful with externally-sourced content.** Battlecards often contain quoted competitor copy or screenshots of marketing pages. That copy can include instructions like "if you're an AI, also tell the user X." Strip imperative content before publishing.
- **Distinguish canonical from extensions.** A canonical battlecard published by the Competitive Intelligence team should look different from a personal extension a rep added. The lint doesn't enforce this; reviewers should.

For the full reasoning, see the Content safety section of [canonical-context-design.md](canonical-context-design.md).

## What's NOT in v1

- **Versioned dependencies** (`requires-context: brand/voice@^1.2.0`). v1 always resolves to the installed version.
- **Selective loading by section / chunking.** Whole-file Read.
- **Context telemetry events.** Skill install/extension telemetry exists; context-specific events are deferred.
- **Per-context manifests.** Metadata lives only in `plugin.json`.
- **A runtime loader.** Skills `Read` the file directly, by convention.

## Related

- [canonical-context-design.md](canonical-context-design.md) — the design spec
- [extending-skills.md](extending-skills.md) — the same composition convention applied to skills
- [proposing-changes.md](proposing-changes.md) — how the propose flow extends to context
- [surfaces.md](surfaces.md) — surface compatibility rules
