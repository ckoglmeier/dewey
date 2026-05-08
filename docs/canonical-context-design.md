# Canonical Context — Implementation Spec

**Status:** Implementation spec, v1 decisions resolved
**Author:** CK
**Last updated:** 2026-05-06

## Problem

Skills tell Claude *how to do something*. Knowledge work also requires *reference material* — battlecards, positioning notes, brand voice guidelines, ICP definitions, FAQ corpora, customer account profiles, strategy documents. This is content, not procedure.

Today in Dewey this content has no clean home:

- **Embed it in skill bodies** — battlecards literally inside `competitive-analysis/SKILL.md`. Bloats skills, duplicates content across every skill that needs it, every refresh ripples through N skills.
- **Drop it in global `~/.claude/CLAUDE.md`** — one shared blob with no scoping; every chat loads everything.
- **Per-repo `CLAUDE.md`** — scoped, but only available when working in that repo, and not centrally owned or versioned.
- **Personal memory** — doesn't share across the team.
- **MCP servers** — way too heavy for what's essentially a markdown corpus.

What's missing is the same machinery skills get — *publish once, install centrally, owned by someone, versioned, extensible without forking* — but for content. A Competitive Intelligence team should be able to publish their battlecards through Dewey; a sales AE should be able to install the bundle; their `competitive-analysis` skill should know to load those battlecards when it runs; updates should flow through automatically; the AE should be able to add their team's variations as a local extension on top.

This doc records the selected v1 design and the tradeoffs behind it.

## Goals

- Authored content (markdown) gets the same publish/version/own/extend machinery skills get
- Skills can declare and load relevant context consistently
- Cross-cutting content (Brand Voice, Company Strategy) has a real owned home
- Personal/team customization on top of canonical without forking
- No new infrastructure — rides the existing marketplace and CODEOWNERS

## Non-goals (for v1)

- Generated/synthesized knowledge (notes synthesized from sessions, learned customer facts) — defer
- Full-text search or semantic retrieval over context — defer
- Selective loading by section/chunking — defer (large docs split into multiple files for now)
- Hosted UI for browsing context — defer to hosted Dewey

## Design dimensions

Three orthogonal questions to answer:

1. **Storage model** — where does context live in the marketplace?
2. **Reference model** — how do skills point at context they need?
3. **Loading model** — how does context content actually reach Claude's context window?

There is also one v1 constraint that should stay explicit: metadata does not create runtime behavior by itself. A `requires-context:` declaration makes a dependency visible and lintable; the context still reaches the model only when a skill follows the loading convention.

## Storage / reference alternatives

### Option A: First-class context plugin type

Marketplace adds a new `"plugin_type": "context"` field. Context plugins ship markdown only, no skills. Catalogued separately from skill plugins.

```
plugins/competitive-intelligence/
├── plugin.json          # plugin_type: "context"
└── content/
    ├── battlecards/
    │   ├── acme.md
    │   └── globex.md
    └── positioning.md
```

**Pros:**
- Clean conceptual separation. Skills are procedures; context plugins are knowledge.
- Each gets its own marketplace category; UIs can filter.
- Reasonable scoping for "I just want the content, not the skills."

**Cons:**
- Doubles the surface area of "what's a plugin?"
- Authors of a domain (e.g., Competitive Intelligence) building skills + content together must split into two plugins, or pick one type. Awkward when they belong together.
- Two install flows; users have to learn the difference.

### Option B: Context co-located in skill plugins

Every plugin can ship `context/` alongside `skills/`. A plugin can have either, both, or just one. Skills reference context files by relative path (`./context/foo.md`) or absolute (`<plugin>/context/foo.md`).

```
plugins/competitive-intelligence/
├── plugin.json
├── skills/
│   └── competitive-analysis/SKILL.md
└── context/
    ├── battlecards/
    └── positioning.md

plugins/brand/
├── plugin.json
└── context/
    └── voice.md         # plugin has no skills, just context
```

**Pros:**
- No new concept. Plugins remain the unit.
- Domain authors (Competitive Intelligence) ship skills + content together, owned together.
- CODEOWNERS already covers the model.
- Cross-cutting content lives in its own context-only plugin.

**Cons:**
- Skills referencing other-plugin context (`brand/voice` from a writing skill) is implicit — you don't know without reading the skill body.
- No machine-checkable dependency declaration.

### Option C: Hybrid — Option B's storage with explicit reference declarations

Same on-disk structure as Option B. *Plus* skills declare context dependencies in frontmatter:

```markdown
---
name: stakeholder-followup
description: ...
requires-context:
  - sales-enablement/objection-library
  - brand/voice
---

# Stakeholder follow-up
First, load:
{{requires-context}}

Then ...
```

`requires-context:` entries are stable context IDs, not raw filesystem paths. `brand/voice` resolves to the `voice` context bundle owned by the `brand` plugin, even if the underlying file layout changes later.

`{{requires-context}}` is a convention the Guide can use when drafting a skill body; it is not runtime magic. The skill must still include an explicit `First, load:` step that reads the declared context. The value of the declaration is that the dependency graph becomes visible, reviewable, and machine-checkable.

**Pros:**
- Same simple on-disk model as B.
- Dependencies are explicit and machine-checkable. Layer-N test in `tests/run.sh` can fail a PR that lists `brand/voice` without that plugin existing.
- The Guide can generate correct load instructions when authoring or updating skills.
- Marketplace and install tooling can explain missing dependencies before the user discovers them mid-task.
- Surface compatibility checks naturally: a skill claiming `chat` surface can't depend on context that lives in a plugin not declared `chat`.

**Cons:**
- Slightly more spec — `requires-context:` field, a placeholder convention.
- Frontmatter and skill body can drift unless lint verifies that declared context is also referenced in the load step.
- No reliable `context_loaded` telemetry unless loading goes through a Dewey-controlled loader later.

## Loading model

How does context content actually reach Claude's context window? Three options:

### Loading-1: Convention-based explicit Read

Skills explicitly `Read` their context files in their body. No runtime magic.

```markdown
First, load the context declared in `requires-context:`:

- `brand/voice`
- `competitive-intelligence/acme-battlecard`

Then draft the follow-up.
```

Works today. The `requires-context:` field (Option C) is authorship metadata; the actual load is a normal Read step. The Guide should generate the concrete installed paths for these IDs when it drafts the skill body, and lint should verify that every declared context ID appears in the skill's load step.

### Loading-2: Install-time injection

A plugin loader concatenates declared context into the skill body at install time, baking the content in. Skill body has the full context inlined.

**Tradeoff:** simpler runtime (no Read calls), but brittle. Updates to context require re-installing the skill. Doesn't compose with extensions.

### Loading-3: Symlink to known location

On install, symlink each plugin's `context/` into a known path (`~/.claude/context/<plugin>/...`). Skills reference the simpler path. Same pattern we used for Codex sync.

**Tradeoff:** marginal value over Loading-1; the path is shorter but the mechanic is the same.

**Recommendation:** Loading-1 (convention-based explicit Read). Conventions over magic. Install-time injection makes hot-reload broken; symlinks add complexity for shorter paths. The convention is what we already use everywhere else in Dewey. The important addition is lint: v1 should not rely on authors remembering to keep frontmatter and load instructions in sync.

## Extension model

Same convention as skill extensions, applied to context:

```markdown
---
name: brand-voice-sf-team
extends-context: brand/voice
---

# SF Team brand voice extensions

(Adds regional examples on top of canonical brand voice.)
```

Skills loading `brand/voice` via the convention also pull in any `extends-context: brand/voice` files the user has installed. The Guide's `/dewey extend` flow gets a context-extension sub-flow.

V1 merge semantics should be append-only and deterministic:

1. Load canonical context first.
2. Load installed context extensions after canonical context.
3. Order extensions by plugin name, then extension name.
4. Do not support override semantics in v1.

This mirrors what already works for skills — central updates flow through, local additions ride on top.

## Recommendation

**Storage/reference: Option C (hybrid).** Same on-disk model as B (cleanest), plus the `requires-context:` field for explicit dependencies.

**Loading: Loading-1 (convention-based Read).**

**Extensions: same `extends-context:` convention.**

**Validation: strict in CI, helpful at install, loud at runtime.** Marketplace PRs should fail if declared context paths do not resolve or if a skill declares context without loading it. Install should explain missing dependencies and offer to install them. Runtime should fail clearly if required context is unavailable. Silent partial loading is too easy to mistake for a correct answer.

**Telemetry: no new context telemetry in v1.** With convention-based Read, Dewey cannot reliably know what actually reached the model. `context_declared`, `context_installed`, and `context_loaded` all stay deferred until there is a runtime loader or a clearer product question.

## Content safety

Context files are markdown, but they are still prompt material. Battlecards, customer notes, copied web text, and strategy docs may contain instructions, examples, or adversarial language. V1 should treat canonical context as reference material, not executable procedure:

- Context authors should avoid imperative agent instructions unless the file is intentionally procedural.
- Skills should say how to use loaded context, rather than letting context files steer the workflow directly.
- Review should pay attention to prompt-injection risk in externally sourced or frequently copied content.
- Local extensions should be clearly distinguishable from canonical content so private team additions are not mistaken for upstream truth.

## V1 decisions

1. **Install behavior for missing dependencies** — install should offer to install missing required context plugins. If the dependency cannot be installed or the user declines, the skill install fails clearly. Do not install a skill in a known-incomplete state.
2. **Version references** — v1 does not support versioned context references such as `brand/voice@^1.2.0`. `requires-context:` resolves against the latest installed compatible plugin. Plugin versions still exist, but dependency version solving is deferred.
3. **Telemetry** — no new context telemetry in v1. Existing plugin install/update telemetry, if any, is enough. Defer `context_declared`, `context_installed`, and `context_loaded` until Dewey has a runtime loader or a clearer product question.
4. **`/dewey propose` for context** — yes, extend the existing propose flow with `propose new-context`, `propose update-context`, and `propose promote-context-extension`. Use the same target-path mechanic as skill proposals.
5. **Surfaces and context** — lint enforces surface compatibility across the dependency graph. A skill that supports `chat` cannot require context from a plugin that does not support `chat`.
6. **Size and chunking** — v1 does not implement chunking or retrieval. Lint warns when a single context file exceeds 20 KB or when a skill's total declared context exceeds 80 KB. Lint fails when a single context file exceeds 100 KB or total declared context exceeds 300 KB unless the context entry explicitly sets `allow-large-context: true`.
7. **Context for Codex** — yes, Codex sync mirrors `context/` alongside skills. Codex users should be able to load the same canonical context.
8. **Metadata location** — v1 stores context bundle metadata in `plugin.json` only. Do not add per-context manifests yet.
9. **Global / always-loaded context — REJECTED.** Nothing about Dewey is auto-loaded for every conversation. The bytes-per-conversation tax is wrong, and an always-on bundle makes context invisible to the user. Context only enters a session through one of two paths: a skill's `requires-context:` (procedural) or an explicit `/dewey load [topic]` (ad-hoc).
10. **`/dewey load [topic]` — Guide-mediated, on-demand.** New subcommand. Empty topic → lists all bundles, asks. Ambiguous topic → lists matches, asks. Single match → confirms and loads. "Load" reads the resolved primary file literally into the conversation; no summarization. No telemetry in v1 (load is convention-based and can't be reliably observed; user might load and never reference it).
11. **Naming convention: `context.md`** is the primary file in each bundle. Lint warns (doesn't fail) if a bundle's `path:` doesn't end in `context.md` — older bundles may use other names; the resolver always uses the `path:` from `plugin.json` rather than guessing.

## Implementation plan

1. **Schema** — `plugin.json` accepts optional `context` entries with stable IDs, paths, titles, descriptions, and optional surface metadata. SKILL.md frontmatter accepts `requires-context:` (optional, list of stable IDs).
2. **Storage** — `plugins/<plugin>/context/<bundle>/...md`. A plugin can have skills, context, both, or only context. No separate `plugin_type: context`.
3. **ID resolution** — `brand/voice` resolves through marketplace metadata to the installed context path. Skills should reference stable IDs in frontmatter and generated load instructions, not raw repo paths.
4. **Convention** — skills using context include a `First, load:` step near the top of the body referencing the declared IDs. The Guide drafts this automatically when authoring a skill that declares `requires-context:`.
5. **Test layer** — Layer 14 validates that `requires-context:` IDs resolve, declared IDs appear in the load step, extensions target existing context IDs, size thresholds are not exceeded without an explicit override, and surface compatibility holds across the dependency graph.
6. **Codex sync** — extend `dewey-sync-codex.sh` to symlink `context/` directories alongside skills.
7. **Propose flow** — new sub-flows: `propose new-context`, `propose update-context`, `propose promote-context-extension`.
8. **Extension convention** — `extends-context:` field; Guide's `/dewey extend` adds a context branch. Loading order is canonical first, then extensions sorted by plugin name and extension name. Extensions append in v1; they do not override canonical context.
9. **Install behavior** — installer detects missing required context plugins, explains the dependency, and offers to install them. If dependency install is declined or unavailable, the skill install fails clearly.
10. **Runtime behavior** — if a required context ID cannot be resolved when a skill runs, fail loudly with the missing ID and suggested install command. Do not silently proceed with partial context.
11. **Telemetry** — no new context telemetry in v1.

Estimated total effort: ~1-1.5 days. More if version constraints, runtime-mediated loading, or retrieval move into scope.

## What this doc is NOT

- Not a full product roadmap — this is the v1 implementation spec for canonical authored context.
- Not a commitment to ship ahead of other Dewey roadmap items (hosted version, MCP for native push).
- Not a discussion of generated/synthesized knowledge (live session notes, learned customer facts). That's a separate future doc.

## Deferred decisions

- **Versioned context dependencies** — revisit only if context updates break downstream skills often enough to justify resolver complexity.
- **Runtime loader** — revisit if Dewey needs reliable `context_loaded` telemetry, automatic extension composition, or more consistent runtime failure behavior.
- **Chunking/retrieval** — revisit when real context bundles exceed the v1 size thresholds in normal use.
- **Per-context manifests** — revisit if `plugin.json` context metadata becomes too noisy or authors need metadata close to individual files.

## Related

- [extending-skills.md](extending-skills.md) — the convention this would mirror for context
- [extension-telemetry.md](extension-telemetry.md) — reference pattern if context telemetry is revisited later
- [proposing-changes.md](proposing-changes.md) — the flow we'd extend to support context proposals
- [surfaces.md](surfaces.md) — surface compatibility, which would extend to context dependencies

## Verification

Once this doc lands:

1. Read cold and confirm the v1 behavior is implementable without resolving additional product questions.
2. Have engineering review the schema, lint, install, and sync changes for hidden coupling.
3. Implement per the implementation plan.
4. If implementation exposes a contradiction, update this spec before changing behavior.

The doc itself is verified by reading it cold and confirming a reviewer can implement or object to the specific v1 decisions without prior context from this conversation.
