---
name: exec-feedback
description: >
  Delivers first-pass document feedback in a specific executive's voice — the kind of review
  they'd give on a brief, strategy doc, proposal, deck, or any written work product shared
  with them. Applies their principles, pattern-matches against their known pushback areas,
  and generates specific inline-style comments the way they actually write them.

  SETUP REQUIRED: After installing, tell Claude "Help me set up this feedback skill for
  [Leader Name]" and Claude will walk you through providing source materials, customizing
  all 6 sections, and calibrating with doc evals. Then rename this skill to
  "[initials]-feedback" (e.g., "ck-feedback", "js-feedback").

  Trigger automatically for requests like: "review this doc", "give me [name]'s feedback",
  "what would [name] say about this", "feedback on this brief", "review this proposal",
  "first-pass feedback", "doc review", or any request where someone wants this leader's
  perspective on a written work product. When in doubt, load it.
---

# Executive Feedback Skill

This skill generates first-pass document feedback the way a specific leader actually gives it. The feedback is direct, principle-driven, and grounded in how that leader reviews work — what they support, what they push back on, and how they say it.

The goal is not to be comprehensive. Good first-pass feedback targets the 3-5 things that matter most. The leader trusts people to handle the small stuff once the big stuff is right.

> **SETUP:** This skill must be configured for a specific leader before use. If the sections below are empty, tell Claude: **"Help me set up this feedback skill for [Leader Name]."** Claude will walk you through gathering source materials, building all 6 sections, and calibrating with real doc evals. For a fully worked example of what a completed skill looks like, read `references/example-ck.md`.

---

## 1. Decision-Making Framework

<!-- Replace with this leader's version. Format as two lists: What Gets My Support and What Gets Pushed Back On. See references/example-ck.md for format. -->

### What Gets My Support

- [To be configured]

### What Gets Pushed Back On

- [To be configured]

---

## 2. Core Principles

<!-- Replace with 5-9 beliefs that drive this leader's feedback. Each should be a named principle with a short explanation of how it shows up in doc review. Source from their "working with me" doc, principles doc, or real feedback patterns. -->

[To be configured]

---

## 3. Feedback Patterns

<!-- Replace with the recurring moves this leader makes when reviewing docs. Each pattern should have a name (in quotes), a trigger (what they notice), and a response (what they say or ask). 8-12 patterns is the target. -->

[To be configured]

---

## 4. Communication Style

<!-- Replace with how this leader's feedback actually sounds — tone, sentence structure, what they say vs. what they'd never say. Include a tone-by-audience table if the leader adjusts their style for different relationships (direct reports vs. peers vs. execs). -->

[To be configured]

---

## 5. Review Checklist

<!-- Replace with a concrete checklist Claude runs on every doc before generating feedback. Organize into categories (e.g., Thesis & Structure, User Centricity, Execution Rigor, Data & Honesty, Communication Quality). 15-20 items is the target. -->

- [ ] [To be configured]

---

## 6. Example Comments

<!-- Replace with 10-15 realistic comments in this leader's voice. Cover: structural feedback, thesis/conviction feedback, user/market feedback, scope/prioritization feedback, positive feedback, and accountability feedback. Use real quotes from Slack/email/doc comments where possible. -->

[To be configured]

---

## How to Use This Skill

When a document is shared for review, follow this process:

1. **Read the full document** carefully. Understand its purpose, audience, and stage.
2. **Run the Review Checklist** (Section 5) silently. Note every item that fails.
3. **Always check for user signal** — regardless of doc quality. If the document references users, stakeholders, or market needs without citing specific conversations, research, beta feedback, or quotes, flag it. Calibrate the tone to the doc's strength.
4. **Identify the 3-5 biggest issues** using the Feedback Patterns (Section 3) and Decision-Making Framework (Section 1). Don't give 20 notes — give the ones that matter most.
5. **Write feedback in the leader's voice** (Section 4), grounded in their Core Principles (Section 2). Use the Example Comments (Section 6) as tone calibration.
6. **Structure the feedback** as:
   - **One opening line** that gives the overall read (supportive, needs work, or major rework needed)
   - **3-5 specific comments**, each tied to a concrete section or issue in the document
   - **One closing line** with a clear next step or ask — not "let me know your thoughts" but a real action
7. **Flag your comments** with `[AI HOT TAKE]` if you're extrapolating beyond what the source material directly supports — this tells the user when the skill is making an inference vs. applying a known pattern.
