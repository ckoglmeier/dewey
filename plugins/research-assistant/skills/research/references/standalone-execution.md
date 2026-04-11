# Standalone Execution Protocol

When a research type skill is invoked directly (not via the research orchestrator),
follow this protocol to run the full research pipeline independently.

---

## Step 1: Company Context

List all `.md` files in `../../research/references/contexts/` that are NOT
`_template.md`. Check each for `CONFIGURED: YES`.

**If 0 configured contexts:**
Ask the user two quick questions: (1) What company is this for? (2) Who are the
customers and main competitors? Copy `_template.md` to
`../../research/references/contexts/[company-name].md`, write in the answers,
and set `CONFIGURED: YES`. Then proceed.

**If 1 configured context:**
Load it automatically. Note which company is active and proceed.

**If 2+ configured contexts:**
List the company names and ask: "Which company context would you like to use?"
Once the user selects, load that file and proceed.

---

## Step 2: Internal Recon (Phase 0)

Before planning web research, check what the organization already knows.

Run in parallel:
1. **Internal docs** - Use the `search` tool with 2-3 relevant queries
2. **Slack** - Use `slack_search_public_and_private` with 2-3 queries
3. **Meetings** - Use `meeting_lookup` if the topic has likely been discussed recently

Summarize findings for the user. Pass to research agents as pre-loaded context.
If these tools are unavailable, skip and note that internal recon was not available.

---

## Step 3: Plan and Present

Using the agent workstreams defined in THIS skill file:

1. Decompose the question into 2-3 agents with non-overlapping scopes
2. Present the plan to the user and wait for approval
3. Each agent should have 3-6 specific sections and a target of ~500-1,500 lines

---

## Step 4: Create Skeletons and Launch

Once approved:

1. Create output directory: `research/[topic]/`
2. Read the shared write protocol from `../../research/references/write-protocol.md`
3. Create skeleton files for each agent
4. Launch ALL agents in parallel using the Task tool with `run_in_background: true`

Each agent prompt must include:
- The research question and their specific scope
- The exact file path to write to
- Section list (numbered, in order)
- Company context (loaded in Step 1)
- Internal findings from Step 2
- The write protocol (verbatim)
- Any type-specific protocols from this skill

---

## Step 5: Monitor

- Check-in at ~30 seconds, ~2 minutes, ~5 minutes, then every 5 minutes
- Use `wc -l` on output files for quick progress checks
- If an agent's line count hasn't changed between two check-ins, stop and relaunch

---

## Step 6: Synthesis

Once all agents complete:

1. Read `../../synthesis/SKILL.md` for synthesis format instructions
2. Launch the synthesis agent to read all output files
3. Apply the type-specific output format from this skill
4. Report the key finding to the user in 2-3 sentences
