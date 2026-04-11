---
name: research
description: >
  Run deep, multi-agent research on any strategic question. Handles the full workflow:
  internal recon (Slack + internal docs), parallel web research agents, progress monitoring,
  and synthesis into a polished prose document.

  Trigger automatically for requests like: "research X", "dig into Y", "do a competitive
  analysis of Z", "help me size the market for", "should we build/buy/partner for", "pull
  together everything we know about", "I need a landscape on", "what do we know about
  [company]", "find companies similar to X", "who else has solved this", "who should I be
  talking to in this space", "find analogs to our model", "build a list of companies worth
  getting introduced to", "map the ecosystem for [market]", "due diligence on [company]",
  "prep me for a meeting with [person]", "what tools exist for [category]", "regulatory
  requirements for [industry]", or any request to investigate a topic, market, or strategic
  question. When in doubt, load it - structured multi-agent research almost always beats
  ad hoc searching.
---

# Research - Multi-Agent Research Orchestrator

Orchestrates deep research across all supported types: market sizing, competitive analysis,
build/buy/partner, company financials, company deep dives, industry trends, analog mapping,
technology landscape, regulatory landscape, due diligence, person profile, and ecosystem
map. Each type has its own skill with agent instructions and output templates. This
orchestrator handles context, recon, planning, launch, monitoring, and handoff to synthesis.

---

## Step 0: Company Context Check (Run First, Every Time)

Before doing anything else, load the correct company context.

### How to check:

List all `.md` files in `references/contexts/` that are NOT `_template.md`.
For each file, check whether `CONFIGURED: YES` is present.

Count the configured contexts.

---

### If 0 configured contexts → Run the Setup Wizard

No context exists yet. Walk the user through setup, one group at a time.
Wait for answers before moving to the next group.

**Group 1 - Company basics:**
- What's the company name?
- What does it do? (One or two sentences.)

**Group 2 - Customers and product:**
- Who are the company's customers? (Type of buyer, industry, size.)
- What are the main products or services?
- Any internal terms, acronyms, or product names Claude should know?

**Group 3 - Competitive landscape:**
- Who are the main competitors?
- Is there a particular market or vertical the company focuses on?

**Group 4 - Research preferences:**
- Who typically uses research outputs? (e.g., executive team, product, sales)
- Any preferences on output format or communication style?

Once answered, copy `references/contexts/_template.md` to
`references/contexts/[company-name].md`, write in the answers, and set
`CONFIGURED: YES`. Confirm to the user which file was created, then proceed.

---

### If 1 configured context → Load it automatically

Read the file, load it into memory, and note which company is active:
"Using [Company Name] context." Then proceed to Phase 0.

---

### If 2+ configured contexts → Ask which one to use

List the company names and ask: "Which company context would you like to use for
this research?" Once the user selects, load that file and proceed.

Example prompt:
> "I found context files for: Acme Corp, Initech, Globodyne. Which would you like
> to use for this research?"

---

### Context management commands

Handle these at any time:

- **"Add a new company context"** → Run the setup wizard above; save as a new file
- **"Update [company] context"** → Re-open that company's file, make the update,
  confirm what changed
- **"List my company contexts"** → List all configured context files with their
  company names
- **"Delete [company] context"** → Confirm with the user, then delete the file
- **"Switch to [company]"** → Load a different context mid-session

---

### Passing context to agents

Once a context is loaded, pass the relevant sections to every research agent:
company overview, customers, products, competitive landscape, and research
preferences. Agents should use this to frame their research and implications.

---

## Phase 0: Internal Recon

Before planning or launching any web research, **check what the organization already knows.**

### Search internal sources (run in parallel):

1. **Internal docs** - Use the `search` tool with 2-3 relevant queries. Look for: prior
   analyses, strategy docs, memos, product briefs related to the topic.

2. **Slack** - Use `slack_search_public_and_private` with 2-3 queries. Look for: recent
   discussions, decisions, shared links, or data points on the topic.

3. **Meetings** - Use `meeting_lookup` if the topic has likely been discussed recently.

### What to do with internal findings:

- **Summarize for the user:** "I found X internal docs and Y Slack threads on this.
  Key existing context: [2-3 sentence summary]. Proceeding to fill the gaps with
  external research."
- **Pass to research agents** as pre-loaded context.
- **Identify the gaps** - what does the organization *not* already know?

If internal recon finds the question is already well-answered internally, say so and
ask whether to proceed with external research or synthesize what already exists.

---

## Phase 1: Plan the Research

> **Note:** Each research type can also be invoked directly as its own skill (e.g.,
> "competitive analysis of X" loads the competitive-analysis skill directly). When
> invoked directly, the type skill runs its own standalone execution protocol — it
> doesn't need this orchestrator. The orchestrator is most useful for complex or
> blended questions, or when the user says "research X" without specifying a type.

### 1. Identify the research type

Match the user's request to one of the research types and **read that type's SKILL.md**
to get agent instructions, section templates, and type-specific rules:

| Type | When to use | Skill to read |
|------|-------------|---------------|
| **Market Sizing** | TAM/SAM/SOM, territory analysis, opportunity sizing | `../market-sizing/SKILL.md` |
| **Competitive Analysis** | Landscape scans, competitor profiles, positioning against rivals in the same domain | `../competitive-analysis/SKILL.md` |
| **Build/Buy/Partner** | Capability gap decisions, M&A targets, partnership evaluation | `../build-buy-partner/SKILL.md` |
| **Company Financial Analysis** | Earnings summaries, M&A target financials, valuation | `../company-financials/SKILL.md` |
| **Business Understanding Report** | Deep business comprehension; no financial figures | `../company-deep-dive/SKILL.md` |
| **Industry & Trend** | Market dynamics, emerging trends, how a space is shifting | `../industry-trend/SKILL.md` |
| **Analog Mapping** | Find structurally similar companies in different domains; map investors and intro paths | `../analog-mapping/SKILL.md` |
| **Technology Landscape** | Map a technology category - tools, capabilities, maturity, adoption, comparison | `../technology-landscape/SKILL.md` |
| **Regulatory Landscape** | Map the regulatory environment for a market, product, or activity | `../regulatory-landscape/SKILL.md` |
| **Due Diligence** | Holistic company evaluation for investment, acquisition, or partnership decisions | `../due-diligence/SKILL.md` |
| **Person Profile** | Background, career, public positions, network, and communication style for meeting prep | `../person-profile/SKILL.md` |
| **Ecosystem Map** | Map players, relationships, dependencies, and power dynamics in a market or platform | `../ecosystem-map/SKILL.md` |

**Type selection guidance:**
- Financial Analysis vs. Business Understanding: Financial = how the company is *performing*.
  Business Understanding = how it actually *works*. Can be combined with separate agents.
- Competitive Analysis vs. Analog Mapping: Competitive = rivals in your domain.
  Analog = structurally similar companies in different domains. Different output goals.
- Technology Landscape vs. Competitive Analysis: Technology Landscape = buyer-side ("what
  should we use?"). Competitive Analysis = seller-side ("who do we compete against?").
- Due Diligence vs. Company Deep Dive: Due Diligence = making a decision about a company
  (produces a verdict). Deep Dive = understanding a company (produces comprehension).
- Ecosystem Map vs. Competitive Analysis: Ecosystem Map includes partners, suppliers,
  and complementary players - not just rivals. Many ecosystem players are potential allies.
- Regulatory Landscape vs. Industry Trend: Regulatory = compliance and legal environment.
  Industry Trend = broader market dynamics.

If the request blends types, read multiple type skills and plan agents for each.

### 2. Understand the question

- What exactly are we trying to learn?
- Who will use this research and for what decision?
- What's the time horizon and urgency?

### 3. Decompose into agent workstreams

Use the agent workstream recommendations from the type skill. Each agent should have:
- A clear, non-overlapping scope
- 3-6 specific sections to write (from the type skill's template)
- A target output of ~500-1,500 lines of markdown

**For Analog Mapping:** Run Step 0 (Extract the Seed DNA) before decomposing.

### 4. Plan the synthesis agent

Runs AFTER all research agents complete. Read `../synthesis/SKILL.md` for synthesis
instructions and type-specific output format overrides.

### 5. Present the plan

```
## Research Plan: [Topic]

**Research type:** [Type name]
**Decision this informs:** [What question does this answer?]

### Agent 1: [Name]
**Scope:** [1-2 sentence scope]
**Sections:**
1. [Section name]
2. [Section name]
3. ...
**Output file:** research/[topic]/[agent-name].md

### Agent 2: [Name]
...

### Synthesis Agent
**Runs after:** All research agents complete
**Output file:** research/[topic]/synthesis.md
```

**Wait for user approval before proceeding.** Do NOT launch agents until confirmed.

---

## Phase 2: Create Skeleton Files

Once the user approves the plan:

1. **Create the output directory:** `research/[topic]/`

2. **Read the shared write protocol** from `references/write-protocol.md`

3. **For each research agent, create a skeleton markdown file** with:
   - Agent name and scope title
   - Status: IN PROGRESS
   - The write protocol (from references/write-protocol.md) - injected verbatim
   - Any type-specific protocols from the type skill
   - Company context (relevant sections from the active context file)
   - Internal findings from Phase 0
   - Numbered section list from the type skill

4. **Create the synthesis skeleton** with similar instructions, noting it should
   read from the other agent output files.

---

## Phase 3: Launch Research Agents

Launch ALL research agents in parallel using the Task tool with `run_in_background: true`.

Each agent prompt MUST include:
1. The research question and their specific scope
2. The exact file path they must write to (absolute path)
3. The section list they must complete (numbered, in order)
4. Company context from the active context file in `references/contexts/`
5. Internal findings from Phase 0
6. The write protocol from `references/write-protocol.md` (copy verbatim)
7. Any type-specific protocols (confidence tags, no-financials rule, etc.)

Use `subagent_type: "general-purpose"` for all research agents.

**IMPORTANT:** Use `run_in_background: true` so agents run in parallel.

After launching, tell the user how many agents are running and their output file paths.

---

## Phase 4: Monitor Progress

### Check-in 1: ~30 seconds after launch
- Read each agent's output file to verify they've started writing
- Report which agents have started, which haven't
- Flag any agent with an empty file

### Check-in 2: ~2 minutes after launch
- Report approximate progress (sections with content, rough line counts)
- Flag any agent that hasn't progressed since last check

### Check-in 3: ~5 minutes after launch
- Report which agents are complete (Status: COMPLETE)
- **STUCK AGENT RULE:** If an agent's line count has NOT increased between two
  consecutive check-ins, stop it immediately with TaskStop and relaunch

### Subsequent check-ins: Every 5 minutes

**How to check:** Use `wc -l` via Bash on all agent output files. Then Read
specific files only if you need to see section progress.

**How to report (keep it concise):**
```
Agent check-in [#N]:
- Agent 1 (Market sizing): ~120 lines, sections 1-3 done, working on 4/6
- Agent 2 (Competitive): ~80 lines, sections 1-2 done, working on 3/5
- Agent 3 (Industry): COMPLETE (185 lines)
```

### Stuck Agent Recovery

1. **Stop the agent** immediately with TaskStop
2. **Read the output file** to see what sections are already complete
3. **Check the agent's process output** (TaskOutput) to extract useful data
4. **Relaunch with a new agent** that:
   - Is told which sections are already complete and to skip them
   - Is given any useful data extracted from the stuck agent
   - Starts by writing pre-loaded data to file FIRST, then searches for more
5. **Monitor the relaunched agent** on the same schedule

---

## Phase 5: Synthesis

Once ALL research agents are complete (or user decides to proceed):

1. **Read the synthesis skill** at `../synthesis/SKILL.md` for output format instructions
2. **Launch the synthesis agent** (foreground or background per user preference)
3. The synthesis agent reads all research agent output files and Phase 0 findings
4. It produces output following the synthesis skill's instructions, applying any
   type-specific overrides
5. **Report to user** when complete with a 2-3 sentence summary of the key finding

---

## Key Rules

1. **Run the Company Context Check (Step 0) before anything else.** Every session.
2. **Never launch agents without user approval of the plan.**
3. **Always run Phase 0 (internal recon) before planning web research.**
4. **Read the type skill before planning agents.** The type skill has the agent
   workstreams, section templates, data sources, and type-specific rules.
5. **Inject the shared write protocol into every agent.** Read it from
   `references/write-protocol.md` and include verbatim.
6. **Every agent gets company context and internal findings.**
7. **Monitor proactively.** Check in on schedule without waiting for the user to ask.
8. **Kill stuck agents immediately.** If line count hasn't changed across two check-ins,
   TaskStop and relaunch.
9. **Agents cannot run Bash.** They have: WebSearch, WebFetch, Read, Write, Edit,
   Glob, Grep. Parse PDFs in the main session before launching agents.
10. **Pre-load data on relaunch.** Extract useful findings from a stuck agent before
    relaunching.
