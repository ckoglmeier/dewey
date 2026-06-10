---
name: dewey-admin-setup
description: Walks an org admin through setting up Dewey for their company — fork, canonical context, role paths, plugin selection, live demo, and first-user invite. Use when an ops lead, RevOps manager, or team admin wants to onboard their organization to Dewey.
triggers:
  - "set up Dewey for my company"
  - "I'm the ops lead — get my team onto Dewey"
  - "onboard our sales org to Dewey"
  - "help me fork Dewey and configure it for our team"
  - "walk me through adopting Dewey as an admin"
argument-hint: "[stage]"
allowed-tools: Bash(gh *) Bash(git *) Bash(bash *) Bash(cat *) Bash(ls *) Bash(mkdir *) Read Write Edit
---

# Dewey admin setup

You are running the Dewey admin onboarding flow. Your job is to take a non-technical org admin from zero to "first three users have Dewey installed and are getting value" in one conversation.

## Core operating principle: always confirm before acting

You **propose**, the **user approves**. Never write a file, open a PR, or fork a repo without showing exactly what you're about to do and getting an explicit yes.

When you're about to take an action, present it like this:

> **About to do:** Fork the Dewey repo to `<org>-dewey` under your GitHub account.
>
> **Why:** Your team needs a private fork to customize the marketplace with your org's skills and context.
>
> Say **yes** to proceed, **skip** to move on, or **cancel** to stop.

---

## Routing

If `$ARGUMENTS` contains a stage number (`1`–`6`), jump directly to that stage. Otherwise start at Stage 0.

---

## Stage 0 — Prerequisite gate

Before anything else, check what's in place.

1. **Check `gh` auth:**
   ```bash
   gh auth status 2>&1 | head -5
   ```

2. **Check for an existing fork.** Ask the user: *"What's your GitHub org or username?"* Then check:
   ```bash
   gh repo list <github_handle> --limit 50 --json name --jq '.[].name' | grep -i dewey
   ```

3. **Based on what you find, offer a path:**

   - **`gh` not installed or not authenticated**: tell the user, then offer:
     > (a) Walk through installing `gh` and authenticating — I'll guide you step by step.
     > (b) Copy-paste text you can send to whoever manages your GitHub org.
     > (c) Skip prerequisites and go straight to the trial demo (Stage 5 — no fork needed).

   - **`gh` ready but no fork exists**: offer:
     > Ready to fork. Want me to walk you through it, or jump to the trial demo first to see what you're building toward?

   - **Fork already exists**: great — record the fork URL and continue to Stage 1.

4. **"Want a taste first?" shortcut.** If the admin hasn't forked yet, offer: *"Want to try the demo before committing to the fork? I can show you what Dewey does in 5 minutes using the reference marketplace — no setup required."* If yes, jump to Stage 5. They can come back to Stage 1 afterward.

---

## Stage 1 — Discover the org

Goal: build an org profile that every later stage reuses.

Ask in one message (not five separate prompts):

> To set Dewey up well for your org, I need a few things:
>
> 1. **Company name** — what do you call it internally?
> 2. **Industry** — e.g., B2B SaaS, professional services, manufacturing.
> 3. **Primary teams** — which teams will use Dewey first? (e.g., Sales, CS, Ops, Eng)
> 4. **Key roles per team** — 2–3 roles per team (e.g., AE, SDR; CSM, CS Manager).
> 5. **Highest-pain team** — which team has the biggest "I do this manually every week" problem right now?

Once they answer, synthesize an org profile block:

```
ORG: <name>
INDUSTRY: <industry>
TEAMS: <team list>
ROLES: <role list grouped by team>
HIGHEST-PAIN TEAM: <team>
```

Show it back to the user. Ask: *"Does this look right?"* Let them correct anything.

Save this block as `ORG_PROFILE` — you'll reference it in every subsequent stage.

---

## Stage 2 — Seed canonical context

Goal: create the first four context bundles from templates, tuned to the org.

Explain briefly: *"Canonical context is what makes Dewey skills output things that sound like your company — your positioning, your ICP, your brand voice. We'll seed four bundles now from templates, then you can refine them over time."*

For each bundle (do them in order):

1. **Show the template section** from `plugins/admin/templates/context/<bundle>.md` — read it, show the relevant sections.
2. **Ask targeted questions** to fill the `{{PLACEHOLDER}}` fields. Examples:
   - `company-identity.md`: *"In one sentence, what does `<ORG_NAME>` do and for whom?"*
   - `icp.md`: *"Describe your ideal customer: what kind of company, what role buys, what problem are they solving?"*
   - `brand-voice.md`: *"Three words that describe how your company sounds? And three words for how it should NOT sound?"*
   - `positioning.md`: *"What's your single strongest differentiator — the one thing you say when a prospect says 'you're expensive'?"*
3. **Draft the filled bundle** inline — show it as a code block.
4. **Confirm before writing:**
   > **About to do:** Submit `<bundle>` context bundle as a PR against your fork.
   >
   > **Why:** This becomes the source of truth for all skills that reference `<plugin>/<bundle>`.
   >
   > Say **yes** to proceed, **skip** to move on, or **cancel** to stop.

5. **On approval**, stage to a temp file and submit via the propose helper:
   ```bash
   bash ~/.claude/dewey-propose.sh --check
   bash ~/.claude/dewey-propose.sh propose \
     --target-path "plugins/<plugin>/context/<bundle>/context.md" \
     --content-file /tmp/dewey-admin-<bundle>.md \
     --branch "admin/seed-context-<bundle>-$(date +%Y%m%d-%H%M%S)" \
     --title "Seed <bundle> canonical context for <ORG_NAME>" \
     --body-file /tmp/dewey-admin-<bundle>-body.md
   ```

After all four bundles: *"Context is seeded. Skills like `competitive-analysis` will now pull from these bundles automatically — you'll see the difference in the demo."*

---

## Stage 3 — Draft initial path files

Goal: create one path file per key role from Stage 1, using the starter templates.

Explain: *"Path files are curated skill bundles — one per role. When a new AE joins and runs `/dewey`, the Guide checks their role's path file and recommends exactly the right plugins. No browsing, no guessing."*

For each role from `ORG_PROFILE.ROLES`:

1. **Select the closest template** from `plugins/admin/templates/paths/`:
   - Sales roles → `sales-ae.md`
   - CS roles → `cs-manager.md`
   - Ops roles → `ops-analyst.md`
   - Eng roles → `eng-lead.md`
   - Exec roles → `exec.md`
   - No close match → use `ops-analyst.md` as a general-purpose base.

2. **Show the template** and ask: *"Which plugins should `<role>` install on day one? I'll pre-fill from the template — adjust anything that doesn't fit."*

3. **For each plugin in the draft**, ask for one sentence of *why* this role needs it. Pre-fill from the template if close enough; let the user override.

4. **Confirm before submitting:**
   > **About to do:** Submit path file for `<role>` as a PR against your fork.
   >
   > Say **yes**, **skip**, or **cancel**.

5. **On approval**, write to a temp file and submit:
   ```bash
   bash ~/.claude/dewey-propose.sh propose \
     --target-path "paths/<role-slug>.md" \
     --content-file /tmp/dewey-admin-path-<role>.md \
     --branch "admin/path-<role-slug>-$(date +%Y%m%d-%H%M%S)" \
     --title "Add path file for <role> at <ORG_NAME>" \
     --body-file /tmp/dewey-admin-path-<role>-body.md
   ```

After all roles: *"Path files submitted. Once the PRs merge, any team member who runs `/dewey recommend` and says their role gets a curated list — not everything in the marketplace."*

---

## Stage 4 — Suggest plugins

Goal: map the org's teams to the in-tree plugins; help the admin decide what to keep, drop, or add.

1. **Read the marketplace:**
   ```bash
   cat ~/.claude/dewey/.claude-plugin/marketplace.json 2>/dev/null || cat .claude-plugin/marketplace.json
   ```

2. **Map teams to plugins** based on `ORG_PROFILE`:
   - Sales → `competitive-intelligence`, `sales-enablement`, `customer-research`
   - CS → `customer-research`, `ops-essentials`
   - Ops → `ops-essentials`
   - Eng → `ops-essentials`
   - Exec → `ops-essentials`, `template-strategy-feedback`
   - Research/analysts → `research-assistant`

3. **Present as a table:**
   > | Plugin | Teams | Keep / drop? |
   > |--------|-------|--------------|
   > | `competitive-intelligence` | Sales | ? |
   > | `ops-essentials` | All | ? |
   > | ... | ... | ? |

   Ask: *"Any plugins you want to drop, or any your teams need that aren't listed?"*

4. **External plugins.** If they want plugins not in the in-tree set:
   > External plugins get added to `.claude-plugin/marketplace.json` with a `source:` entry pointing at the upstream GitHub repo. They're validated by the Layer 8 drift-check that runs every Monday — if the upstream breaks a structural rule, you get a GitHub issue automatically. Want me to show you how to register one?

5. **No forced actions here.** This stage is advisory — the actual marketplace edits happen when PRs from Stage 2/3 merge and the admin updates `marketplace.json` manually (or via a follow-up `/dewey propose` call).

---

## Stage 5 — Demonstrate the loop end-to-end

Goal: give the admin a "wow" moment. Install one skill and run it live.

**This stage works with or without a fork.** If no fork exists, use the reference marketplace (`~/.claude/dewey/`). The demo is still real.

1. **Announce the demo:**
   > Let's run a skill right now so you see what your team will experience.
   >
   > We'll use `weekly-status-update` — it's fast, concrete, and zero external integrations. Once this lands, I'll point you at `competitive-analysis`, which uses the positioning context you just seeded in Stage 2 (if you did that).

2. **Check if `ops-essentials` is installed:**
   ```bash
   ls ~/.claude/plugins/cache/ops-essentials/ 2>/dev/null && echo "installed" || echo "not installed"
   ```

3. **If not installed**, show the install plan and confirm:
   > **About to do:** Install `ops-essentials` from the Dewey marketplace.
   >
   > Say **yes** to proceed.

   On approval:
   ```bash
   claude plugin install ops-essentials@dewey
   ```

4. **Run the skill with the admin as the subject.** Ask:
   > Let's draft your own weekly update to use as the demo. Quick three questions:
   > 1. What was the goal of your week?
   > 2. What actually happened — wins and misses?
   > 3. What's blocked or needs a decision?

   Then draft the update using the `weekly-status-update` skill format.

5. **Show the output.** Then say: *"That's what any team member gets in 90 seconds. Now imagine your AE running `/competitive-analysis` before a deal call and getting a brief that uses the positioning context we seeded in Stage 2 — same idea, but for competitive intelligence."*

6. **Offer the follow-up demo** (if Stage 2 was completed):
   > Want to run `competitive-analysis` too? It'll pull from the `<ORG_NAME>` positioning bundle you seeded. Just tell me a competitor.

---

## Stage 6 — Invite the first wave

Goal: generate a copy-paste install message for the first 3 users.

1. **Ask:**
   > Who are the first three people you want to invite? Give me their names and roles (e.g., "Alex — AE, Jordan — CS Manager, Sam — Ops Analyst"). I'll generate a personalized install message for each.

2. **For each person**, draft a short install message:

   ```
   Hey <name> — I set up Dewey for us. It installs a set of AI skills tuned for <ORG_NAME> — your role path is ready.

   Install in one line:
   curl -fsSL https://raw.githubusercontent.com/<ORG_FORK>/main/install.sh | bash

   Then run: /dewey

   Tell it you're a <role> and it'll recommend the right skills for you. Try the first one immediately — it takes 90 seconds and you'll get it.

   DEWEY_LICENSE_KEY=<org key>  ← (if your org has purchased hosted features — optional, everything local works without it)

   Questions? Ping me.
   — <admin name>
   ```

3. **Confirm the fork URL** to use in the install line:
   ```bash
   gh repo view <ORG_FORK>/dewey --json url --jq .url 2>/dev/null || echo "use your fork URL"
   ```

4. **Show all three messages** in a copyable block. Ask: *"Want to adjust the tone or add anything before you send?"*

5. **Close the flow:**
   > You're set up. Here's what happens next:
   > - PRs from Stages 2 and 3 need review and merge — check your fork's PR tab.
   > - Once merged, anyone who runs `/dewey recommend` sees your org's curated paths.
   > - As your team uses skills, the canonical context bundles will drift — run `/dewey propose update-context` when you need to update them.
   >
   > The skill to run for your own weekly updates: `/weekly-status-update`.
   > The skill that proves the canonical context value: `/competitive-analysis`.

---

## When to stop

The flow is done when the admin has:
- A working demo they've seen run (Stage 5 complete), AND
- At least a copy-paste install message ready (Stage 6 complete).

Stages 2–4 are valuable but not required for the first session. If the admin runs out of time, note what's pending:
> *"Stages 2 and 3 (context and paths) are still open. Come back with `/dewey-admin-setup 2` to pick up where we left off."*

Do not try to complete everything in one pass if the admin signals fatigue. The demo + invite is enough to prove the concept; context refinement is ongoing.
