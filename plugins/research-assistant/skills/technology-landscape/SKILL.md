---
name: technology-landscape
description: >
  Map a technology category - what tools exist, their capabilities, maturity, adoption,
  and how they compare. Use when someone asks "what tools exist for [category]", "map
  the [technology] space", "what are our options for [capability]", "evaluate [category]
  tools", or any request to understand what's available in a technology category. Different
  from competitive-analysis (you're evaluating tools for your own use, not positioning
  against rivals) and industry-trend (tactical tool mapping, not macro forces). Can be
  invoked directly or via the research orchestrator.
---

# Technology Landscape Research Type

**Standalone execution:** If invoked directly (not via the research orchestrator),
follow the protocol in `../research/references/standalone-execution.md` to run the
full pipeline: company context -> internal recon -> plan -> launch agents -> monitor ->
synthesize.

Use this type when the goal is to map a technology category - understanding what tools,
platforms, or solutions exist, how they compare, and which might be right for a
specific use case.

**Important distinctions:**
- **Technology Landscape vs. Competitive Analysis:** Technology landscape is buyer-side
  ("what should we use?"). Competitive analysis is seller-side ("who do we compete
  against?"). If the company being researched IS one of the vendors, use competitive
  analysis instead.
- **Technology Landscape vs. Industry Trend:** Technology landscape is tactical ("what
  tools exist right now?"). Industry trend is strategic ("where is this market going
  over 2-3 years?").

---

## When to Use This Type

- "What tools exist for [data observability / MLOps / customer data platforms / etc.]?"
- "Map the [category] vendor landscape"
- "We need a [capability] - what are our options?"
- "Evaluate the top [category] platforms"
- "What should we use for [technical need]?"

---

## Recommended Agent Workstreams

For most technology landscapes, plan 2-3 agents:

**Agent 1: Category Definition and Vendor Map**
Sections:
1. Category definition - what does this technology category do? What problem does it
   solve? What are the sub-categories or segments within it?
2. Vendor map - comprehensive list of vendors in the category, organized by segment
   or tier. Include: name, one-line description, funding/stage, notable customers.
3. Market structure - how is this category organized? Who are the leaders, challengers,
   niche players? Is it consolidating or fragmenting?
4. Adoption landscape - how widely adopted is this category? What percentage of
   potential buyers have deployed a solution? What's driving adoption or resistance?

**Agent 2: Capability Deep Dives**
For the top 5-8 vendors in the category, cover:
1. Core capabilities - what does it actually do? What are its strengths?
2. Architecture and integration - cloud/on-prem/hybrid? API-first? Key integrations?
3. Target buyer - who is this built for? Enterprise, mid-market, SMB? Technical or
   business user?
4. Pricing model - how do they charge? Per seat, usage-based, platform fee?
5. Maturity signals - how long in market? Customer count? G2/Gartner reviews?
6. Limitations - what does it NOT do well? Where do users complain?

**Agent 3: Evaluation Framework and Recommendations**
Sections:
1. Selection criteria - what should a buyer prioritize when evaluating this category?
   Rank by importance for the company's context.
2. Feature comparison matrix - top vendors across the key selection criteria. Table
   format with clear ratings or notes.
3. Maturity assessment - where is each vendor on the maturity curve? Early, growing,
   mature, declining?
4. Recommendations by use case - "If you need X, consider Y. If you need A, consider B."
   Tailored to the company's context from company-context.

---

## Technology Maturity Framework (REQUIRED)

Every technology landscape must assess vendor maturity. Classify each vendor:

- **Emerging** - Less than 2 years in market, limited customer base, rapid iteration,
  high feature velocity but stability concerns. Evaluate: innovation potential, funding
  runway, team credibility.
- **Growing** - 2-5 years in market, expanding customer base, product stabilizing,
  beginning to differentiate. Evaluate: growth trajectory, customer retention, roadmap
  execution.
- **Mature** - 5+ years in market, established customer base, stable product, slower
  feature development. Evaluate: market share trend, competitive pressure, innovation
  stagnation risk.
- **Declining** - Losing market share, talent departing, legacy technology, possible
  acquisition target. Evaluate: migration path, support commitment, sunset risk.

State the classification with evidence for each vendor profiled.

---

## Adoption Signal Framework (REQUIRED)

Don't just list vendors - assess whether this category is actually being adopted.

### Adoption evidence hierarchy (strongest to weakest):
1. **Named customer deployments** with production use confirmed
2. **Revenue/ARR figures** showing growth trajectory
3. **Job postings** mentioning the tool (indicates real usage, not just evaluation)
4. **Community activity** (GitHub stars, Stack Overflow questions, conference talks)
5. **Analyst inclusion** in magic quadrants, waves, or market guides
6. **Vendor marketing claims** (weakest - treat skeptically)

### Adoption blockers to investigate:
- Is the category too new for risk-averse buyers?
- Are there integration barriers with existing stacks?
- Is the ROI case unclear?
- Are there regulatory or compliance concerns?
- Is there a "good enough" alternative already in place?

---

## Key Data Sources

- **G2, Gartner Peer Insights, TrustRadius** - user reviews and ratings
- **Gartner Magic Quadrants, Forrester Waves** - analyst positioning (may be paywalled;
  note category name and year if you can find it)
- **Product Hunt, GitHub** - for emerging/developer-focused tools
- **Crunchbase / PitchBook** - funding and investor data
- **Company websites and docs** - feature details, pricing, integration lists
- **Job postings** - which companies are hiring for expertise in which tools

---

## Output Structure for Synthesis

1. **Category thesis** - 2-3 sentences: what is this category, what's its current state,
   and what should a buyer know before evaluating?
2. **Category map** - all vendors organized by segment or tier. Table format.
3. **Vendor profiles** - one paragraph per major vendor (top 5-8) covering capabilities,
   target buyer, maturity classification, and key strengths/limitations.
4. **Feature comparison matrix** - table: vendors across rows, key capabilities across
   columns. Use clear indicators (strong/adequate/weak/absent).
5. **Maturity landscape** - visual or table showing where each vendor sits on the
   maturity curve.
6. **Recommendations** - tailored to the company's context. "If your priority is X,
   evaluate Y first." Specific, not generic.

---

## Common Pitfalls

- **Listing vendors without evaluating them.** A list is not a landscape. Every vendor
  needs a maturity classification and capability assessment.
- **Treating all vendors equally.** Spend more time on the 3-5 that are realistic
  options for the company's context. Don't give equal depth to a 10-person startup
  and a $5B platform.
- **Missing the "good enough" alternative.** Sometimes the best answer is "use the tool
  you already have." If an existing tool covers 80% of the need, say so.
- **Confusing analyst positioning with reality.** A Gartner Leader might be losing
  market share to an emerging challenger. Check adoption signals, not just quadrant
  placement.
- **No selection criteria.** A landscape without a framework for choosing is a catalog,
  not research.
