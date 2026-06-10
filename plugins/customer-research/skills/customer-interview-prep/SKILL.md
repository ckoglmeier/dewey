---
name: customer-interview-prep
description: Prepares the user for a customer interview with open-ended questions and a one-page brief. Use when the user mentions an upcoming customer call, discovery, win/loss, churn, or research interview.
triggers:
  - "help me prep for my customer interview with Acme tomorrow"
  - "I have a discovery call with a new prospect, get me ready"
  - "prep me for a win/loss interview with the buyer who churned last month"
  - "what should I ask in my churn call with Sarah?"
  - "I'm doing a research interview with a customer this afternoon — draft the brief"
argument-hint: "[customer-name or account]"
---

# Customer interview prep

Help the user walk into a customer interview already knowing what they need to learn. Output a one-page brief they can read in 5 minutes.

## What to do

1. **Ask what the interview is for.** Discovery, win/loss, churn, expansion, research? The interview type determines the questions. Don't guess.
2. **Pull what's known about the customer.** If the user has notes, files, or prior call transcripts they can share, ask for them. If they mention CRM data (Salesforce, HubSpot), ask if you can access it.
3. **Surface the assumptions.** Before drafting questions, list 3–5 things the user *believes* about this customer. The interview's job is to test those beliefs, not confirm them.
4. **Draft 8–10 open-ended questions** that map to the interview type. No yes/no questions. No leading questions. Use the templates below.
5. **Output a one-page brief** in the format below.

## Question templates by interview type

**Discovery:**
- Walk me through how you handle [problem] today.
- What was happening that made you start looking for a solution?
- Who else is involved in deciding on something like this?
- What does success look like 12 months after you buy?

**Win/loss:**
- Take me back to when you first heard about us — what was the situation?
- What were the alternatives you seriously considered?
- What almost stopped you from picking us? *(or, if loss: what made you go the other way?)*
- If you were us, what would you change about how we sold to you?

**Churn:**
- When did you first feel like this wasn't working?
- What would have had to be true for you to stay?
- What are you using now? How is it different?

**Expansion:**
- What's changed about your team or workflow since you started using us?
- What are you using us for that surprised you?
- What's the biggest unmet need on your team right now — even if it's not something we do?

## Output format

```
# {Customer name} — Interview Brief

**Type:** [discovery / win-loss / churn / expansion]
**When:** {date/time}
**Who:** {names + roles}

## What we believe (assumptions to test)
1. ...
2. ...
3. ...

## What we know
- ...

## Questions to ask
1. ...
2. ...
...

## What "success" for this interview looks like
[1–2 sentences: what the user should walk away knowing they didn't know before]
```

## When to stop

The brief is done when the user could open it 5 minutes before the call, skim it, and walk in with three specific things they want to learn. If they read it and say "I already knew all this," the assumptions section is too weak — push harder on the unknowns.
