# Executive Feedback Skill — Setup Guide

This skill teaches Claude to deliver first-pass document feedback in a specific executive's voice. It captures how that person actually reviews work — their principles, patterns, communication style, and the things they consistently push back on — so anyone on their team can get a realistic preview of the feedback before sharing the real thing.

The SKILL.md ships with a fully worked example (built for Chandler Koglmeier, SVP Product Growth at Guild) so you can see the format and depth of each section. When you install the skill and tell Claude to set it up, Claude will walk you through replacing that example with your leader's content.

**After setup, rename the skill** from `exec-feedback` to `[initials]-feedback` (e.g., `ck-feedback`, `js-feedback`) so it's clear whose lens is being applied. You can rename in **Customize > Skills > exec-feedback > Edit name**.

---

## What You'll End Up With

A SKILL.md file with 6 sections:

1. **Decision-Making Framework** — What gets this leader's support vs. what gets pushed back on. Modeled as two lists: green-light patterns and red-flag patterns.
2. **Core Principles** — The 5-9 beliefs that drive all of their feedback. The "why" behind every comment.
3. **Feedback Patterns** — The recurring moves they make when reviewing docs. Named patterns like "Where's the thesis?" or "This is three docs in one."
4. **Communication Style** — How their feedback actually sounds. Tone, sentence structure, what they say vs. what they'd never say. Calibrated by audience.
5. **Review Checklist** — A concrete checklist Claude runs on every doc before generating feedback.
6. **Example Comments** — 10-15 realistic comments in the leader's voice, covering structural feedback, thesis feedback, scope feedback, user-centricity, and positive reinforcement.

---

## Step 1: Gather Source Materials

The skill is only as good as the source material. You need documents that capture how this leader thinks, communicates, and gives feedback. Here's what to look for:

### Required (at minimum 2 of these)

- **"How I work" or "Working with me" doc** — Many leaders have one. This is the single best source because it's the leader describing their own values, communication preferences, and expectations in their own words.
- **Principles or values doc** — If the leader has written down their principles for how to build, how to make decisions, or how to operate, this is gold. It becomes the backbone of Sections 1 and 2.
- **Real feedback examples** — Slack messages, Google Doc comments, email threads, or meeting notes where the leader gave actual feedback on someone's work. These calibrate the tone and make Section 6 authentic. Search Slack for messages from the leader containing words like "feedback," "thesis," "tighter," "user," "metrics," or the names of docs/briefs they reviewed.

### Strongly Recommended

- **Strategy docs the leader wrote** — Their own writing shows how they think arguments should be structured. If they lead with a thesis, your skill should flag docs that don't.
- **Docs the leader approved** — These show what "good" looks like to them. Critical for calibration — you don't want the skill manufacturing problems on strong work.
- **Docs the leader pushed back on** — These show what triggers their red flags. If you can find the feedback they gave alongside the doc, even better.

### Nice to Have

- **Performance reviews they wrote** — Shows how they evaluate people and what they value.
- **Slack messages in leadership channels** — Shows how they frame context, share work, and communicate with peers vs. direct reports.
- **Presentation decks they authored or reviewed** — Extends the skill beyond written docs.

---

## Step 2: Give Claude Access

Claude needs to be able to read the source materials. How you do this depends on where the materials live:

### Google Docs / Drive
If you have Glean or a similar connector, Claude can read Google Docs directly via URL. Just paste the links. If not, export as PDF or copy-paste the content into the conversation.

### Slack
If Claude has Slack access (via MCP connector), search for the leader's messages with relevant keywords. Good searches to run:

- `from:@[leader] feedback doc review brief`
- `from:@[leader] "thesis" OR "conviction" OR "tighter" OR "user problem"`
- `from:@[leader] strategy proposal recommendation`

Look for messages where they're reacting to someone's work, sharing their own docs with commentary, or giving inline direction.

### Uploaded Files
You can upload PDFs, Word docs, or text files directly. If the leader has a "Working with me" doc as a PDF, just upload it.

### Screenshots
If you have screenshots of Google Doc comments or Slack threads, Claude can read images. Upload them as-is.

---

## Step 3: Build the Skill

Once you have your source materials loaded, ask Claude to build the skill. Here's a prompt template:

```
I'd like to build a feedback skill for [Leader Name] that delivers
first-pass document feedback in their voice. Use the following
6-section structure:

1. Decision-Making Framework (What Gets My Support / What Gets Pushed Back On)
2. Core Principles
3. Feedback Patterns
4. Communication Style
5. Review Checklist
6. Example Comments

Here are the source materials:
- [Link or upload: "Working with me" doc]
- [Link or upload: Principles doc]
- [Link or upload: Any real feedback examples from Slack/email]

Please propose a plan before building.
```

Claude will review the materials, propose a plan for each section, and ask for your go-ahead before writing.

---

## Step 4: Calibrate with Doc Evals

This is the most important step. Once the skill is drafted, test it against real documents to make sure it's calibrated correctly. You need three types:

### Test Type 1: A Doc the Leader Pushed Back On
Share a doc that this leader gave critical feedback on. The skill should identify similar issues. If the leader said "this is too long and there's no thesis," the skill should catch that too.

**What to check:** Does the skill's feedback match the leader's actual feedback? Are the priorities right (catching the big things, not just nitpicking)?

### Test Type 2: A Doc the Leader Approved
Share a doc the leader greenlit. The skill should be mostly positive — affirming what's strong, with maybe 1-2 minor sharpening notes.

**What to check:** Is the skill manufacturing problems that aren't there? Is it giving the same intensity of feedback as it did on the weak doc? If so, recalibrate — the skill needs to differentiate between strong and weak work.

### Test Type 3: A Doc the Leader Wrote
Share something the leader authored. The skill should still give honest feedback (everyone has blind spots), but the tone should reflect that this is strong work with minor areas to tighten.

**What to check:** Does the skill identify real gaps, or does it just praise everything? The leader's own docs often pass on thesis and structure but may lack user signal or have thin sections.

### How Many Tests?

Start with 3 (one of each type). If those feel right, you're done for V1. If something is off — the tone is wrong, it's missing a key pattern, it's too harsh on approved docs — iterate on the skill and re-test.

For a more rigorous eval, test on 6-8 docs across all three types. The goal is to confirm the skill differentiates appropriately: hard feedback on weak docs, targeted notes on good docs, mostly affirmation on approved docs.

---

## Step 5: Install and Use

Once calibrated, package the skill as a `.skill` file and install it:

1. In Claude, go to **Customize > Skills > + Upload a skill**
2. Upload the `.skill` file
3. The skill will trigger automatically when someone says "review this doc," "give me feedback on this," or similar phrases

### Tips for Your Team

- **Tell people what stage the doc is at.** The skill gives different feedback on a rough draft vs. a final proposal. If the user says "this is an early draft, looking for structural feedback," the skill will adjust.
- **Share docs the leader actually reviewed** as additional training data over time. The more real examples, the sharper the calibration.
- **Iterate after real use.** The first version will be ~80% right. After a few weeks of use, collect examples where the skill's feedback diverged from the leader's actual feedback and use those to refine.

---

## How It Works Under the Hood

The skill has Claude follow this process on every doc review:

1. Read the full document
2. Run the Review Checklist silently (Section 5)
3. Check for user signal (the most common leader feedback pattern)
4. Identify the 3-5 biggest issues using Feedback Patterns (Section 3) and the Decision-Making Framework (Section 1)
5. Write feedback in the leader's voice (Section 4), grounded in Core Principles (Section 2)
6. Structure as: one opening line (overall read) → 3-5 specific comments → one closing line with a clear next step
7. Flag any extrapolation with `[AI HOT TAKE]` so the reader knows when the skill is inferring vs. applying a known pattern

The skill targets the 3-5 things that matter most. It doesn't try to be comprehensive — it trusts the team to handle the small stuff once the big stuff is right.

---

## Claude Setup Walkthrough

When a user installs this skill and says **"Help me set up this feedback skill for [Leader Name]"**, Claude should follow this sequence:

### 1. Gather Source Materials
Ask the user to provide at least 2 of the following. Explain why each matters:
- **"Working with me" or "How I work" doc** — The leader's own description of their values, communication style, and expectations. This is the single best source.
- **Principles or values doc** — Written principles for how to build, decide, or operate.
- **Real feedback examples** — Slack messages, Google Doc comments, emails where the leader gave actual feedback on someone's work.
- **Strategy docs the leader wrote** — Shows how they structure arguments.
- **Docs the leader approved** — Shows what "good" looks like (needed for calibration in Step 3).
- **Docs the leader pushed back on** — Shows what triggers red flags.

### 2. Build the Skill
Using the source materials, replace all 6 sections in SKILL.md with content specific to this leader:
1. Decision-Making Framework (What Gets Support / What Gets Pushed Back On)
2. Core Principles (5-9 beliefs that drive their feedback)
3. Feedback Patterns (named recurring moves, e.g., "Where's the thesis?")
4. Communication Style (tone, sentence patterns, what they'd never say)
5. Review Checklist (concrete items Claude checks on every doc)
6. Example Comments (10-15 realistic comments in the leader's voice)

Also update the SKILL.md frontmatter description to reference the specific leader and their common trigger phrases.

### 3. Calibrate with Doc Evals
Run the skill against 3 real documents:
- **A doc the leader pushed back on** — Skill should catch similar issues
- **A doc the leader approved** — Skill should be mostly positive with 1-2 minor notes
- **A doc the leader wrote** — Skill should give honest but calibrated feedback

If the skill over-criticizes approved docs or misses key patterns on rejected docs, iterate on the relevant sections.

### 4. Rename
Once the user confirms the skill is calibrated, instruct them to rename it from `exec-feedback` to `[initials]-feedback` in **Customize > Skills > exec-feedback > Edit name**.
