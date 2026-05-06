---
name: competitive-analysis
description: Analyzes a competitor's positioning, messaging, pricing, and recent moves. Use when the user asks about a competitor by name, wants a battlecard, or is preparing for a deal where a specific competitor is in the conversation.
argument-hint: "[competitor-name]"
requires-context:
  - competitive-intelligence/positioning
---

# Competitive analysis

Produce a structured competitive analysis of the named competitor. The output should be useful in a real sales or product conversation — not a generic SWOT.

## First, load context

Before analysing the competitor, load the canonical positioning context so the brief reflects current company truth, not the model's guesses:

- Stable ID: `competitive-intelligence/positioning`
- Look for it at one of these paths (read whichever exists):
  - `~/.claude/classroom/plugins/competitive-intelligence/context/positioning/positioning.md` (Claude Code or Cowork)
  - `~/.codex/context/competitive-intelligence/positioning/positioning.md` (standalone Codex)

Read the file in full. If neither path exists, stop and tell the user the `competitive-intelligence` plugin appears to be incomplete — they should run `/classroom update`. Do not proceed with a brief based on guessed positioning.

## What to gather

Work through these in order. If the user has given you a specific deal context, weight your answers toward that context.

1. **Positioning** — How does the competitor describe themselves on their homepage and pricing page? What's their one-line pitch? Who do they target?
2. **Pricing** — Public pricing tiers, what's included, what's excluded. If pricing is "contact us," note that as a signal.
3. **Recent moves** — Last 90 days: product launches, funding, exec changes, acquisitions, public partnerships. Use the WebSearch tool if available.
4. **Where they win** — Common reasons buyers pick them. Look for review sites (G2, Capterra), case studies, and customer logos.
5. **Where they lose** — Common complaints from real users. Negative G2 reviews, Reddit threads, ex-customer signals.
6. **How we differ** — Three specific, defensible differences. Avoid feature lists — focus on what changes for the buyer.

## Output format

```
# {Competitor Name} — Competitive Brief

**One-line pitch:** ...
**Target buyer:** ...
**Pricing model:** ...

## Recent moves (last 90 days)
- ...

## Where they win
- ...

## Where they lose
- ...

## Three things we say differently
1. ...
2. ...
3. ...

## Sources
- ...
```

Always cite your sources at the end. If a section is thin because the data isn't public, say so explicitly — don't fill in plausible-sounding fiction.

## When to stop

You're done when a sales rep could read this in 90 seconds before a call and walk in with one specific differentiation talking point. If the brief is longer than one screen, cut.
