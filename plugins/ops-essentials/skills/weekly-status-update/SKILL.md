---
name: weekly-status-update
description: Drafts a weekly status update for the user's team, role, or project. Use when the user mentions writing a weekly update, status report, Friday wrap, or async standup.
triggers:
  - "write my weekly status update for the engineering team"
  - "Friday wrap-up time, draft my update"
  - "help me write a weekly report for my manager covering the Acme project"
  - "draft my async standup for this week"
  - "I need to send a weekly status to the exec team — help me draft it"
argument-hint: "[audience or project]"
---

# Weekly status update

Draft a status update that someone will actually read. Most weekly updates are bad because they list activity instead of outcomes. Yours won't.

## What to ask before drafting

1. **Who is this for?** (Manager, peer team, exec, customer, broad company.) Audience determines the tone and what you cut.
2. **What was the goal of the week?** Not "what did you do" — what was supposed to happen.
3. **What actually happened?** Wins, misses, surprises.
4. **What's blocked or at risk?** This is the most valuable section for a manager-audience update — never skip it.
5. **What's next?** One or two specific things, not a laundry list.

If the user has Slack, calendar, Linear, or notes you can pull from, ask before drafting.

## Output format

```
# Week of {date} — {role or team}

**Goal this week:** [one sentence — what was supposed to happen]

## Wins
- [outcome, not activity. "Closed XYZ deal" not "had 8 calls this week"]

## Misses / surprises
- [be honest. one or two items.]

## Blocked or at risk
- [what you need help with, who you need it from]

## Next week
- [1–2 specific commitments]
```

## Style rules

- **Outcomes, not activity.** "Shipped onboarding redesign" not "spent 12 hours on onboarding work."
- **Numbers when you have them.** "3 net new customers" beats "good week on sales."
- **Cut anything that's just busy-work signaling.** If a line doesn't change a reader's decision or update, delete it.
- **Length: under 200 words.** If it's longer, the reader will skim and miss the asks.

## When to stop

The update is done when the user reads it back and can point to the *one decision or action* they want their reader to take. If there isn't one, ask: "What do you want them to do after reading this?" and rewrite the asks section.
