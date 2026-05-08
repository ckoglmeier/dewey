# Cowork integration audit (2026-05-06)

How Cowork actually surfaces and uses Dewey plugins, based on
filesystem inspection of a live Cowork install. What works automatically,
what's a parallel system, and what we can't verify without UI access.

## Scope

The audit answers: when a user has both Cowork installed and Dewey
installed, what does the user actually see and what does Cowork actually
do with our skills, context, paths, and metadata?

Method: probe `~/.claude/plugins/`, `~/.claude/scheduled-tasks/`, and
`~/Library/Application Support/Claude/` to see what state Cowork stores
about Dewey and what fields it consumes.

## Findings

### 1. Cowork shares `~/.claude/plugins/` with Claude Code — no separate registration

`known_marketplaces.json` is the single source of truth for both Cowork and
Claude Code CLI. Dewey appears as a `directory`-source entry alongside
`ck-skills`, `claude-plugins-official`, etc. There's no Cowork-specific
mirror or override; whatever's in this file is what Cowork sees.

**Implication:** the install-once-reach-everywhere story for skills is real.
No work needed to "make Dewey work in Cowork" beyond what we already do
for Claude Code.

### 2. Cowork has a SECOND parallel system: "Claude Extensions" (DXT format)

`~/Library/Application Support/Claude/Claude Extensions/` and
`extensions-installations.json` track a different package format —
**DXT** (Anthropic's Desktop Extension format). DXT extensions are
MCP-server packages with their own manifest shape:

```json
{
  "dxt_version": "0.1",
  "name": "chrome-control",
  "display_name": "Control Chrome",
  "server": {
    "type": "node",
    "entry_point": "server/index.js",
    "mcp_config": { "command": "node", "args": ["..."] }
  }
}
```

These are **not** Dewey plugins and **not** Claude Code plugins.
They're a distinct distribution channel for MCP server bundles. Currently
populated only with first-party Anthropic extensions (`chrome-control`).

**Implication:** Dewey does nothing for the DXT channel. If we ever
want to ship MCP servers through Dewey-the-marketplace, we'd need to
either learn the DXT format or stick with the Claude Code plugin
mechanism (which can reference MCP servers through `plugin.json`).

### 3. Cowork ignores our `surfaces:` field

Cowork shows plugins from `~/.claude/plugins/` regardless of what
`surfaces` declares. Our Guide-side filtering (drop chat-only skills when
the surface is claude-code, etc.) is advisory for *our* Guide and doesn't
travel into Cowork's UI.

**Implication:** if a plugin claims `surfaces: ["chat"]` only, Cowork will
still surface it in its plugin browser even though it can't really run
there. Today this isn't a real problem because we don't ship any chat-only
plugins. Future risk.

### 4. No Dewey-specific badging or source-grouping in Cowork's UI

From the registry's perspective, `dewey` is one of several
marketplaces. The `name` field on each entry (`competitive-intelligence`,
`exec-feedback`, etc.) is the only differentiator the user sees. There's
no "from your company's marketplace" group or badge.

**Implication:** for adopters whose companies fork Dewey, end users
won't see a visible "this is your company's curated catalog" cue in
Cowork. Discoverability relies on naming convention and the Guide
(`/dewey`) as the entry point.

### 5. Cowork's scheduled-tasks are skill-shaped — Dewey skills can be scheduled trivially

`~/.claude/scheduled-tasks/<name>/SKILL.md` is the format. Each scheduled
task is literally a SKILL.md directory the scheduler runs. Example
(actual user task):

```markdown
---
name: daily-skill-review
description: Update skills to keep in sync
---

Look at my private skills folder on github and update any skills
locally from there.
```

Scheduling a Dewey skill from Cowork is just "create a SKILL.md
that says '/<dewey-skill> [args]'" in `~/.claude/scheduled-tasks/`.
The native scheduler picks it up.

**Implication:** the "we deferred scheduling to Cowork" story has a
concrete shape. Users add a thin wrapper SKILL.md; Cowork's scheduler
fires it. Worth documenting in `scheduling.md` (and we should — see
follow-up below).

## What we couldn't verify without UI access

These need an actual person looking at Cowork's "Customize → Browse
plugins" panel:

- **Categories and tags rendering.** marketplace.json carries `category`
  and `tags` per entry. Does Cowork's browser show them as filters?
  Group plugins by category? Hidden?
- **Multi-skill plugin display.** A plugin like `research-assistant` has
  15 skills inside. Does Cowork show one entry (the plugin) or expand to
  15? If one entry, how does the user pick a specific skill from it?
- **Path file surfacing.** Our `paths/sales-ae.md`,
  `paths/ops-analyst.md` are part of Dewey but live outside the
  plugins/ tree. Does Cowork's UI know about them or ignore them entirely?
- **Marketplace source distinction.** Multiple marketplaces register at
  once (`dewey`, `ck-skills`, `claude-plugins-official`). Is the
  source visible in the browser, or do all entries blend?
- **Install/uninstall affordances.** Does Cowork show a one-click install
  button? Does uninstall clean up correctly?

## Follow-ups (from this audit)

1. Document the "schedule a Dewey skill from Cowork" wrapper pattern
   in `docs/scheduling.md` — concrete example of a thin SKILL.md in
   `~/.claude/scheduled-tasks/<name>/` that delegates to a Dewey skill.
2. Visual UI walkthrough by an actual user (CK or someone else with
   Cowork open) to fill in the unverified items above. Not actionable
   without that.
3. If Cowork's UI doesn't render `category` / `tags` from marketplace
   entries, those fields are dead weight for the Cowork audience.
   Consider whether to keep them in our marketplace.json.

## What this changes about the roadmap

Nothing structurally. The audit confirms:
- "Cowork shares ~/.claude/" claim is accurate
- The roadmap's `surfaces:` description (advisory, not runtime-enforced)
  is honest
- Scheduling-deferred-to-Cowork has a real concrete path

It identifies one new doc-task (scheduling.md update) and one open
research-task (UI walkthrough). Neither is a blocker.
