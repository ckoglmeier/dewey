# Research Assistant Plugin

Multi-agent research orchestrator that runs deep, parallel research across 12
specialized types with internal recon, web research, and prose-first synthesis.
Supports multi-company context — configure one or many company profiles for
tailored research.

---

## How It Works

There are two ways to run research:

**Via the orchestrator (recommended for complex or blended questions):**
1. Say "research X" — the `research` orchestrator skill loads
2. Orchestrator checks company context (or runs setup wizard on first use)
3. Orchestrator runs internal recon (Slack, docs, meetings) to find existing knowledge
4. Orchestrator identifies the research type and reads that type's skill for instructions
5. You approve the research plan
6. Orchestrator launches parallel agents, monitors progress, recovers stuck agents
7. Synthesis skill combines outputs into a single thematic prose document

**Via direct type invocation (faster for targeted questions):**
1. Say "competitive analysis of X" or "size the market for Y"
2. The matching research type skill loads directly
3. It runs the full pipeline autonomously: context → recon → plan → agents → synthesis

Both paths produce the same quality output. Direct invocation skips the orchestrator's
type-selection step, which is useful when you already know what type of research you want.

---

## Research Types

| Skill | Trigger Examples | Key Frameworks |
|-------|-----------------|----------------|
| **competitive-analysis** | "who competes with us", "competitive landscape" | Momentum Framework, Positioning Matrix, Direct/Indirect/Adjacent categorization |
| **industry-trend** | "what's happening in [market]", "how is [space] shifting" | Signal vs. Noise classification, Temporal Framing (4 horizons), Source Credibility Hierarchy |
| **market-sizing** | "how big is the market", "what's the TAM" | Penetration Rate Discipline, TAM Skepticism Framework, Private Market Sizing guidance |
| **analog-mapping** | "find companies similar to X", "who else solved this" | Business Model DNA extraction (7 dimensions), Archetype routing |
| **build-buy-partner** | "should we build or buy", "M&A targets for" | Decision Rigor Framework, Switching Cost Reality Check, Do-Nothing Evaluation |
| **company-deep-dive** | "deep dive on [company]", "how does [company] work" | Business Model Anatomy (7 dimensions), Moat Assessment, Walk the Talk |
| **company-financials** | "pull the financials on [company]", "earnings summary" | Source Hierarchy, Financial Red Flags Checklist, Structured earnings format |
| **technology-landscape** | "what tools exist for [category]", "evaluate [tech] options" | Technology Maturity Framework, Adoption Signal Framework |
| **regulatory-landscape** | "compliance requirements for [market]", "how is [activity] regulated" | Regulatory Certainty Framework, Compliance Burden Assessment |
| **due-diligence** | "due diligence on [company]", "should we invest in [company]" | Risk Scoring Matrix, Deal Breaker Checklist, Thesis Validation |
| **person-profile** | "prep me for a meeting with [person]", "who is [person]" | Source Priority hierarchy, Meeting Prep Brief format |
| **ecosystem-map** | "map the ecosystem for [market]", "who are the key players" | Ecosystem Power Framework, Relationship Mapping Protocol |

## Supporting Skills

| Skill | What It Does |
|-------|-------------|
| **synthesis** | Combines research agent outputs into thematic prose. Has type-specific output format overrides for each research type. Not directly invocable. |
| **eval** | Evaluates research output quality against type-specific rubrics. Directly invocable. |

---

## Multi-Company Context

The plugin supports research across multiple companies. Context files live in
`research/references/contexts/`.

- **First use:** The orchestrator walks you through a setup wizard to create your
  first company context.
- **One context:** Loaded automatically.
- **Multiple contexts:** The orchestrator asks which company to use for each session.
- **Management commands:** "Add a new company context", "Update [company] context",
  "List my company contexts", "Delete [company] context", "Switch to [company]".

You can also skip context setup entirely and run research generically.

---

## Architecture

### Shared references (apply to all types):
- **Write protocol** (`research/references/write-protocol.md`) — Injected into every
  agent. Enforces the Search → Write → Search → Write pattern. Includes source URL
  validation: every URL cited must be one actually visited.
- **Company contexts** (`research/references/contexts/`) — Per-company context files
  loaded at session start and passed to every agent.
- **Context template** (`research/references/contexts/_template.md`) — Template for
  creating new company contexts.
- **Standalone execution** (`research/references/standalone-execution.md`) — Protocol
  for running the full pipeline when a type skill is invoked directly.

### Type-specific references:
- **Analog mapping** has DNA extraction templates (generic + 4 archetypes) in
  `analog-mapping/references/`

### Quality controls:
- Every synthesis follows type-specific output format with required sections
- Length discipline targets prevent padding (see synthesis skill)
- Instructions-leak prevention: output files begin with document title, no agent boilerplate
- Competitive analysis requires competitive set validation before agents launch
- Industry trend requires Signal/Noise/Too Early classification on every trend
- Due diligence requires deal breaker checklist run every time
- Regulatory landscape requires certainty tagging on every regulation
- Market sizing requires penetration waterfall, not just headline TAM

---

## Adding a New Research Type

1. Create `skills/[new-type]/SKILL.md` with frontmatter (include description with
   trigger examples)
2. Include: When to Use, Recommended Agent Workstreams, Key Data Sources, Output
   Structure for Synthesis, Common Pitfalls
3. Add a standalone execution preamble pointing to `../research/references/standalone-execution.md`
4. Add the type to the orchestrator's type selection table in `research/SKILL.md` Phase 1
5. If the type needs a custom synthesis format, add an override in `synthesis/SKILL.md`
6. Add length guidance to the synthesis skill's Length Discipline table
7. Add a type-specific eval rubric in `eval/SKILL.md`

---

*Research runs best*
*when agents search, then they write —*
*prose before padding*
