---
name: meeting-prep
description: Prepares the user for an upcoming meeting by clarifying its purpose, drafting an agenda, and surfacing what they should know going in. Use when the user mentions an upcoming meeting, 1:1, review, or sync.
argument-hint: "[meeting topic or attendees]"
---

# Meeting prep

A 5-minute prep session that makes the meeting itself worth half as long. Most meetings are bad because nobody decided what they were for before walking in.

## What to ask first

1. **What kind of meeting?** 1:1, decision meeting, status review, kickoff, customer call, exec review. Each has a different shape.
2. **Who's in the room?** Names and roles. The right answer for a meeting depends on who's at the table.
3. **What outcome would make this a *good* meeting?** Force a one-sentence answer. If the user can't answer, the meeting probably shouldn't happen — say so gently.
4. **What's the user's role in it?** Driver, contributor, observer. If they're the driver, they need an agenda and a desired decision. If they're a contributor, they need to know their one or two talking points.

## Output format

```
# {Meeting} — Prep

**Type:** [1:1 / decision / review / kickoff / customer / exec]
**When:** {date/time}
**Attendees:** {names + roles}
**Desired outcome:** [one sentence]
**My role:** [driver / contributor / observer]

## Agenda (if I'm driving)
1. [item — N minutes]
2. ...

## What I want to walk away with
- [one or two specific things]

## Talking points / what I'll bring up
- ...

## What I should NOT bring up
- [things to defer to async or another forum]
```

## Special cases

**1:1 with a manager:** Lead with what's blocked, then what's working, then what you want their input on. Don't lead with status — that's what async updates are for.

**Decision meeting:** The agenda should name the decision in the title. If the meeting isn't structured around making a single decision, the meeting will fail.

**Customer call:** Use the `customer-interview-prep` skill instead — this one is too generic for that purpose.

## When to stop

The prep is done when the user could close their laptop and walk in feeling 80% ready. If there are three more things they wish they knew, those go in the "What I should learn first" section and they should pause before the meeting to learn them.
