# Extending skills (the composition convention)

Central Classroom skills are **immutable to most users**. You shouldn't fork `competitive-analysis` to add your team's quirks — if you do, you fall off the update path. The next time the central maintainer ships an improvement, your fork won't get it.

Instead, Classroom uses a **composition convention**: a local extension is a standalone skill that *references* the parent and adds your steps.

## How it works

A local extension is just a SKILL.md with two things:

1. An `extends:` field in the frontmatter naming the parent skill.
2. A first instruction in the body that says "load and follow the parent skill in full, then do these additional things."

That's it. There's no runtime magic. Claude reads the body, sees the instruction to load the parent, loads it, and then layers your additions on top.

## Example

Central skill: `competitive-analysis` (lives in the `competitive-intelligence` plugin).

Your team needs the same brief, but always with a Gong call lookup and a battlecard appended in your team's template. You write:

```markdown
---
name: sales-gong-deepdive
description: Competitive analysis with Gong call evidence and our team's battlecard format. Use when prepping for a deal with a known competitor.
extends: competitive-analysis
---

First, load and follow the `competitive-analysis` skill in full.

Then additionally:

1. Pull the last 5 Gong calls for the named account using the Gong MCP server.
2. Find every mention of the competitor by name. Quote each one verbatim with the call date and rep name.
3. Append a battlecard section using our team's standard format:
   - "Why they say yes to us"
   - "What to ask if they're leaning the other way"
   - "What NOT to say"
4. Output the whole thing as a single markdown file ready to paste into our deal channel.
```

## Where extensions live

| Scope    | Path                                                 |
| :------- | :--------------------------------------------------- |
| Personal | `~/.claude/skills/<extension-name>/SKILL.md`         |
| Project  | `.claude/skills/<extension-name>/SKILL.md`           |
| Team     | `dojo-extensions-<team>/skills/<extension-name>/SKILL.md` (in a team-managed git repo, distributed via its own marketplace) |

The personal and project paths are standard Claude Code skill locations — extensions are just regular skills that follow the convention. Nothing special needs to be installed.

## Why this matters

When the central maintainer of `competitive-analysis` ships a v2 with better source-citation rules, **your extension gets the upgrade automatically**. The first line of your extension is "load and follow the `competitive-analysis` skill in full" — so whatever the latest central version says, that's what runs. Your additions stay layered on top.

If you had forked it instead, you'd be stuck on v1 forever, manually merging changes whenever you noticed the central one had moved.

## Letting the Guide draft an extension for you

The fastest way to write an extension is to let the Guide do it:

```
/classroom extend competitive-analysis
```

The Guide reads the parent, asks what you want to add, drafts the extension, shows you the draft, and writes the file only after you approve. See the Guide skill for details.

## When NOT to extend

If you want a *completely different* skill — same problem domain but different methodology — just write a new skill from scratch. Don't extend `competitive-analysis` to make `customer-research`. Extension is for *adding* to a parent, not replacing it.

A useful test: if your extension's body starts with "actually, ignore the parent and instead do…" — that's a fork, not an extension. Write a new skill.
