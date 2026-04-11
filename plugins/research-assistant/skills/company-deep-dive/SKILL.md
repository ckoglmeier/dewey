---
name: company-deep-dive
description: >
  Deep dive on a company's business model, strategy, and competitive position - no
  financials, pure business understanding. Use when someone asks "tell me about [company]",
  "how does [company] work", "deep dive on [company]", "what does [company] actually do",
  or any request for business comprehension rather than financial analysis. Can be invoked
  directly or via the research orchestrator.
---

# Company Deep Dive - Business Understanding Report

**Standalone execution:** If invoked directly (not via the research orchestrator),
follow the protocol in `../research/references/standalone-execution.md` to run the
full pipeline: company context → internal recon → plan → launch agents → monitor →
synthesize.

Use this type when the goal is **deep business understanding**, not financial
analysis. The output is a structured narrative report. A reader who finishes it
should be able to explain this business accurately at a dinner table, name the
competitors, explain why customers buy, and articulate what could go wrong.

> **Need financial figures, earnings summaries, or M&A valuation analysis?**
> Use the company-financials type instead.

This type applies to public and private companies. For public companies, the
4 most recent earnings call transcripts are required for Sections 7, 8, and 9.
If fewer than 4 are available, state why and proceed with what you have - do not
silently drop to 1.

**HARD CONSTRAINT: No financial figures anywhere in this report.** No revenue, no
margins, no multiples, no price targets, no market cap. No investment recommendations
of any kind. This is not a style preference - it is a rule. If the user wants
financials, that's a Financial Analysis request - plan separate agents.

---

## Business Model Anatomy (REQUIRED)

Every company deep dive must produce a clear business model anatomy in Section 1 or
Section 3. The reader should understand how this company creates, delivers, and captures
value — not just what the company does. Cover all 7 dimensions:

### The 7 dimensions:

1. **Value creation** — What does this company make or do that someone will pay for?
   Not the marketing pitch — the actual product or service, described concretely.
2. **Customer segments** — Who pays? Who uses? Are they the same person? If B2B2C or
   multi-sided, explain each side.
3. **Revenue mechanics** — How does money flow? Subscription, transaction, take-rate,
   licensing, hardware + consumable, project-based? What's the unit economics story?
4. **Distribution / go-to-market** — How do customers find and buy this? Direct sales,
   PLG, channel partners, embedded in another platform? What's the CAC structure?
5. **Defensibility / moat** — What makes this hard to replicate? Be honest. If the moat
   is thin, say so. Common moats: network effects, switching costs, regulatory capture,
   proprietary data, brand, scale economics. Common non-moats claimed as moats:
   "first mover advantage," "our team," "our culture."
6. **Cost structure** — What are the major cost lines? Is this a high-gross-margin
   software business or a low-margin services business with a tech wrapper? (Note:
   no specific financial figures — describe the structure, not the numbers.)
7. **Value chain position** — Where does this company sit in its industry's value chain?
   What's upstream, what's downstream? Who has leverage over whom?

### Moat assessment:

For Section 5 (Competitive Landscape), apply this honest moat test:

- **Strong moat** — Competitor would need 3+ years AND significant capital to replicate
  the advantage. Customer switching costs are high and measurable. Examples: regulatory
  approvals, network effects with critical mass, proprietary data from years of operation.
- **Moderate moat** — Advantage exists but could be eroded in 1-3 years by a well-funded
  competitor. Examples: brand, distribution relationships, accumulated expertise.
- **Weak moat** — Advantage is primarily execution speed or market timing. Could be
  replicated by any competent team with funding. Examples: feature lead, "first mover,"
  current customer relationships without structural switching costs.
- **No moat** — The company competes on execution and price. This is fine — many great
  businesses have thin moats — but say so plainly rather than inventing one.

State the moat assessment explicitly in Section 5 with the reasoning.

---

## When to Use This Type

- "Help me truly understand [company]"
- "I want to know this business inside and out before a meeting"
- "Give me a deep dive on [company] - how it actually works, who the customers are,
  what management has been saying"
- "I need to be able to speak intelligently about [company]'s business model"
- Any request where the goal is business comprehension, not financial evaluation

---

## Depth Mandate

No length limit. Write as deep as the company demands.

If a company has 4 segments, cover all 4 in depth. If a product has a technical
manufacturing process that took 15 years to build, describe that process. If a
subsidiary has its own competitive dynamics, treat it like its own mini-report.

Cut only what is genuinely redundant. Never cut because of length.

---

## Required Sources (Non-Negotiable for Public Companies)

1. **4 quarterly earnings call transcripts** - the most recent four. Seeking Alpha,
   Motley Fool, or the company's investor relations page. These are mandatory for
   Sections 7, 9, and parts of 8. If you cannot find all 4 after trying all sources,
   explain specifically what you found and why the rest is unavailable.
2. **Latest annual report** - for segment structure, product descriptions, business
   model detail, and management discussion section.
3. **Company website** - product pages, segment pages, About Us, IR section.
4. **Web search** - industry size, competitors, recent news, any analyst coverage
   containing specific data points.

---

## Recommended Agent Workstreams

### Agent 1: Business Foundation (Sections 1-3)
- Section 1: What the company does
- Section 2: Business segments
- Section 3: Products and business detail

Primary sources: Annual report, company website, web search.

### Agent 2: Market & Competitive Position (Sections 4-6)
- Section 4: Customers
- Section 5: Competitive landscape
- Section 6: Industry

Primary sources: Annual report, web search, industry reports.

### Agent 3: Concall Intelligence (Sections 7-9)
- Section 7: Growth triggers (from concalls only)
- Section 8: Key risks
- Section 9: Walk the talk

Primary sources: All 4 earnings call transcripts. This agent must locate and read
all 4 before writing anything.

### Agent 4: Scenarios (Section 10)
- Section 10: Bull / base / bear scenarios

Primary sources: Reads output from Agents 1-3 before writing. Must be launched
after the other three complete.

---

## Section-by-Section Instructions

### Section 1: What the Company Does

Open with a plain-language explanation of the business. No jargon. No "leading player."
Just what they actually do.

Then go deeper:
- The founding story if it explains the current business - pivotal decisions, how the
  company evolved, what they used to be vs. what they are now
- The core value proposition: what specific problem do they solve and for whom
- The technical nature of the product or service: what makes it hard to make, deliver,
  or replicate
- A concrete example of the product or service in action - walk through what they
  actually do for a customer, step by step if needed

Do not stop at the surface. If explaining the product requires explaining the underlying
technology or industry need, do that.

### Section 2: Business Segments

Mandatory for any company with more than one meaningful segment or division.
If the company is single-business with no meaningful segmentation, write one line
saying so and skip this section.

For each segment, write a full sub-section covering:
- **What it does** - specific products/services, geographies, end markets, customer types. Prose, not a list.
- **The core capability** - what took years to build? What would be hard to replicate?
- **Why it exists as a separate entity** - different technology, acquisition history, different economics.
- **Its competitive position** - competitors within this segment specifically.
- **How it fits into the group** - margin engine, growth bet, cash cow, strategic option.
- **Revenue mix %** - the only quantitative data allowed in narrative sections.

### Section 3: Products and Business Detail

Go deeper on actual products, manufacturing, operations, and business mechanics:
- Full product catalogue with explanations
- Technical specifications or capabilities that matter
- Manufacturing or delivery process
- Geographies and export markets
- Notable milestones

Write with enough specificity that a visual (value chain diagram, segment infographic)
could be made from it.

### Section 4: Customers

Go beyond naming industries. Explain the buying relationship:
- Who specifically buys: industries, named accounts if public, geography
- For each major customer type: who makes the buying decision, what criteria, sales cycle
- Why they choose this company: specific reasons, not generic ones
- Switching costs: qualification testing, regulatory approval, installed-base lock-in
- Concentration: if one or two customers dominate, explain the dynamic
- Contract structures: long-term agreements, spot business, recurring retainer

### Section 5: Competitive Landscape

Explain the structure of the industry and where this company sits in it:
- Who the real competitors are - name them, for each segment separately if relevant
- Why this company wins or loses against each major competitor
- Barriers to entry: how high are they really?
- Market share distribution and why
- Structural shifts: consolidation, new entrants, technology disruption
- Where this company is strong and where it is exposed

Do not force a moat narrative if the data doesn't support one.

### Section 6: Industry

Cover the industry with enough depth that the reader understands the demand environment:
- What drives demand for this company's products
- Industry size and growth trajectory (cite sources inline)
- Where this company's markets sit in the global supply chain
- Import substitution dynamics if relevant
- Regulatory environment
- Cyclicality: how does this industry behave across economic cycles
- Tailwinds and headwinds at the industry level (not company level)

### Section 7: Growth Triggers

Extract directly from the 4 concall transcripts. Every trigger must have a source -
concall date and quarter.
- Forward-looking only: new commissionings, customer wins, market entries, product launches
- Be specific: name the plant, the customer type, the product, the timeline
- Cite the concall: "(Q3 FY26 concall, Feb 3 2026)"
- No current or past numbers
- If a trigger was mentioned across multiple concalls, note that it has been repeated

Use blockquotes for particularly specific or striking management statements.
If 6+ triggers, add a summary table.

### Section 8: Key Risks

Identify what could break the business model. For each risk:
- Name the risk clearly
- Explain the mechanism: how exactly does this play out?
- Calibrate it: low-probability catastrophic, or high-probability moderate drag?
- Connect to concall statements where possible

Generic risks (forex, inflation, competition) only earn a place if there is something
specific about this company's exposure to them.

### Section 9: Walk the Talk

Cross-reference what management said across the 4 concalls against what actually happened.
Write as narrative paragraphs, not a table.
- Start with the oldest concall: what did management guide for?
- Move through subsequent concalls: was it delivered?
- Build a picture of consistency: accurate, optimistic, conservative, or erratic
- Call out specific promises kept (with quote and outcome)
- Call out specific promises missed or quietly dropped (with quote and what happened)
- Conclude with a plainly stated assessment

A promise-vs-outcome table can supplement the narrative if 4+ trackable commitments.

### Section 10: Scenarios

Three scenarios: bull, base, bear. Each is a short story, not a financial model.
No numbers. No targets. Just narrative.
- **Bull:** What has to go right? 2-3 year story if everything works.
- **Base:** Most likely path if management delivers roughly as guided.
- **Bear:** What could genuinely go wrong? Ground in real risks from Section 8.

Each scenario: 2-4 paragraphs.

---

## Writing Rules (Non-Negotiable)

- **No financial figures.** No revenue, margins, EPS, multiples, price targets, or
  market cap anywhere in the report.
- **No investment recommendations.** No buy/sell/hold. No advisory language.
- **No superlatives** unless factually verifiable with a source.
- **No corporate jargon:** synergies, value-added, end-to-end solutions, leveraging,
  robust, holistic.
- **No em dashes.** Use regular dashes (-).
- **Every sentence must add genuine understanding.** No filler.
- **Every quantitative claim needs an inline source URL.**
- **Blockquotes for management quotes** - use when original words add specificity.
- **Tables** - use when comparisons across multiple attributes would be hard in prose.
- **Write like pitching at a dinner party to someone very smart and very skeptical.**

---

## Common Pitfalls

- **Stopping at the surface of what the company does.** If you can't explain the
  technical reason why this product is hard to replicate, you haven't gone deep enough.
- **Naming competitors without explaining the competitive dynamic.**
- **Growth triggers without concall citations.**
- **Walk the Talk as sentiment analysis.** Requires specific dated promises cross-referenced
  against specific outcomes.
- **Generic scenarios.** Bull/base/bear must be specific to this company's situation.
- **Forcing a moat narrative.** If the company doesn't have durable competitive
  advantages, say so plainly. Use the moat assessment framework (strong/moderate/
  weak/none) and state it explicitly.
- **Skipping the business model anatomy.** If a reader can't explain how money flows
  through this company after reading Sections 1-3, the deep dive failed. Cover all
  7 dimensions of the Business Model Anatomy.
- **Confusing company narrative with company reality.** The company's website says
  what they want you to believe. Concalls, customer reviews, and competitor filings
  say what's actually happening. Prioritize evidence over narrative.
