---
name: regulatory-landscape
description: >
  Map the regulatory environment for a market, product, or activity. Use when someone
  asks "what are the regulations for [industry]", "compliance requirements for [product]",
  "how is [activity] regulated", "regulatory risk for [market]", "what legislation is
  pending for [topic]", or any request to understand the legal and regulatory landscape
  before entering a market or launching a product. Can be invoked directly or via the
  research orchestrator.
---

# Regulatory Landscape Research Type

**Standalone execution:** If invoked directly (not via the research orchestrator),
follow the protocol in `../research/references/standalone-execution.md` to run the
full pipeline: company context -> internal recon -> plan -> launch agents -> monitor ->
synthesize.

Use this type when the goal is to understand the regulatory environment - what rules
apply, who enforces them, what's changing, and what the compliance burden looks like
for a specific market, product, or activity.

**Important distinction:** Regulatory landscape is about the legal and compliance
environment. Industry trend covers broader market dynamics including but not limited
to regulation. If the question is "what's happening in healthcare?" use industry trend.
If the question is "what do we need to comply with to sell healthcare software?" use
regulatory landscape.

---

## When to Use This Type

- "What are the compliance requirements for [product/market]?"
- "How is [activity] regulated in [jurisdiction]?"
- "What's the regulatory risk if we enter [market]?"
- "What legislation is pending that affects [industry]?"
- "Map the regulatory landscape for [category]"

---

## Recommended Agent Workstreams

For most regulatory landscapes, plan 2-3 agents:

**Agent 1: Current Regulatory Framework**
Sections:
1. Regulatory bodies - who regulates this space? Federal, state, international?
   Name specific agencies, their jurisdiction, and their enforcement posture.
2. Key regulations and requirements - what are the actual rules? Name specific
   statutes, regulations, or standards (e.g., GDPR, HIPAA, SOX, PCI-DSS).
   For each: what it requires, who it applies to, penalties for non-compliance.
3. Compliance burden assessment - how hard is it to comply? What does a company
   need to do (certifications, audits, data handling, reporting)?
4. Jurisdiction matrix - if the regulations differ by geography, create a
   comparison table: jurisdiction x key requirements.

**Agent 2: Regulatory Direction and Risk**
Sections:
1. Pending legislation - what bills, proposals, or regulatory actions are in
   progress? Name them, their status, likely timeline, and expected impact.
2. Enforcement trends - is enforcement tightening or loosening? Recent enforcement
   actions, fines, or precedent-setting cases.
3. Industry lobbying and advocacy - who is lobbying for/against regulation?
   What are the major industry positions?
4. Regulatory risk assessment - what's the probability and impact of regulatory
   change? Which changes would help vs. hurt the company's position?

**Agent 3: Strategic Implications**
Sections:
1. Compliance strategy options - build in-house, hire compliance team, use a
   compliance platform, partner with a regulated entity?
2. Competitive implications - does regulation create barriers to entry (moat) or
   level the playing field? Who benefits from the current regulatory structure?
3. Timeline and sequencing - what needs to happen first for market entry? What's
   the critical path through compliance?
4. Regulatory arbitrage opportunities - are there jurisdictions with lighter
   regulation where the company could start? Sandbox programs?

---

## Regulatory Certainty Framework (REQUIRED)

Every regulation or requirement discussed must be tagged with its certainty level:

- **ENACTED** - Law or regulation is in effect. Compliance is required now.
  Cite the specific statute or regulation number.
- **FINAL RULE** - Regulation has been finalized by the agency but may not yet be
  in effect. Compliance date is known.
- **PROPOSED** - Proposed rule or pending legislation. Comment period may be open.
  State the current status and expected timeline.
- **EXPECTED** - No formal proposal yet, but credible signals suggest regulation is
  coming (agency statements, executive orders, industry consensus). State the
  evidence and estimated timeline.
- **SPECULATIVE** - Industry discussion or advocacy for regulation, but no credible
  signal that it's imminent. Note as context, not as a compliance requirement.

Never present proposed or speculative regulation as if it were enacted. The
distinction between "you must comply with X" and "X might be required in 2 years"
is critical for decision-making.

---

## Compliance Burden Assessment (REQUIRED)

For each major regulation identified, assess the compliance burden:

| Dimension | What to assess |
|-----------|---------------|
| **Cost** | What does compliance cost? (Build vs. buy compliance tools, legal fees, audit costs, ongoing monitoring) |
| **Time** | How long does it take to achieve compliance from scratch? |
| **Expertise** | What specialized knowledge is required? Can existing team handle it or do you need to hire? |
| **Ongoing maintenance** | Is this a one-time certification or ongoing reporting/auditing? |
| **Business impact** | Does compliance change how the product works, what data you can collect, or how you go to market? |

Rate each as Low / Medium / High with a brief explanation.

---

## Key Data Sources

- **Government agency websites** - actual text of regulations, guidance documents,
  enforcement actions (e.g., SEC, FTC, FDA, OCC for US; ICO for UK; EU Commission)
- **Federal Register / Congress.gov** - pending legislation and proposed rules (US)
- **EUR-Lex** - EU legislation and proposals
- **Law firm client alerts** - practical interpretation of new regulations (search
  "[regulation name] client alert" or "[regulation name] law firm analysis")
- **Industry associations** - compliance guides, lobbying positions, industry responses
- **Compliance platforms** - Vanta, Drata, OneTrust often publish compliance guides
  for specific frameworks
- **Enforcement databases** - CFPB enforcement actions, FTC settlements, GDPR fines
  tracker

---

## Output Structure for Synthesis

1. **Regulatory thesis** - 2-3 sentences: what's the overall regulatory posture for
   this space? Is it heavily regulated, lightly regulated, or in transition?
2. **Regulatory map** - which bodies regulate what, and under which frameworks.
   Table format for multi-jurisdiction.
3. **Key requirements** - prose description of the 3-5 most important regulatory
   requirements. For each: what it requires, who it applies to, certainty level.
4. **Compliance burden summary** - table: regulation x burden dimensions (cost, time,
   expertise, maintenance, business impact).
5. **Regulatory direction** - what's changing? Pending legislation, enforcement trends,
   likely trajectory over 1-3 years.
6. **Strategic implications** - what does this mean for the company's market entry,
   product design, or competitive position? Specific actions.

---

## Common Pitfalls

- **Treating regulations as static.** Regulatory environments change. Always cover
  pending legislation and enforcement trends, not just current law.
- **Listing regulations without assessing burden.** Naming GDPR is not useful.
  Explaining what GDPR compliance actually requires for this specific product is.
- **Missing jurisdiction differences.** "Regulated in the US" is meaningless without
  specifying federal vs. state, and which states matter.
- **Confusing proposed with enacted.** A bill in committee is not a law. Tag certainty
  levels on everything.
- **Ignoring enforcement posture.** A regulation that exists but isn't enforced has
  different implications than one with active enforcement. Check recent cases.
- **Skipping the "so what."** A regulatory map without strategic implications is a
  reference document, not research.
