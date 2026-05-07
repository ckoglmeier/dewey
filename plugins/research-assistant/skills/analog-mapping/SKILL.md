---
name: analog-mapping
description: >
  Find analog companies - structurally similar businesses in different domains, with
  investor rosters and intro paths. Use when someone asks "find companies similar to X",
  "who else has solved this", "find analogs to our model", "build a list of companies
  worth getting introduced to", or any request to map structurally similar companies
  across industries. Can be invoked directly or via the research orchestrator.
---

# Analog Mapping Research Type

**Standalone execution:** If invoked directly (not via the research orchestrator),
follow the protocol in `../research/references/standalone-execution.md` to run the
full pipeline: company context → internal recon → plan → launch agents → monitor →
synthesize.

Use this type when the research question is about finding companies that have solved
a structurally similar problem - not competitors in the same domain, but analogs in
adjacent ones. The goal is to identify who to learn from, talk to, or get introduced to,
and to map the investor networks that make those introductions reachable.

**Important distinction:** Analog Mapping is NOT Competitive Analysis. The companies
found are not competitors - they operate in different domains. The question is not
"how do we beat them" but "what can we learn from them, and can we get a warm
introduction?" Do not frame the synthesis as positioning or differentiation analysis.
The output goal is warm introductions and pattern learning.

---

## When to Use This Type

- "Find companies similar to X"
- "Who else has solved this kind of problem?"
- "Who should I be talking to in this space?"
- "Find analogs to our model"
- "What companies have done what we're trying to do, but in a different domain?"
- "Build a list of companies worth getting introduced to"
- "Who's cracked [specific mechanic] in another industry?"
- Any request that starts with seed companies and asks for broader pattern-matching

---

## Step 0a: Identify the Model Archetype

Before extracting DNA, identify which of the four archetypes best describes the seed
company's model. This determines which template to use in Step 0b.

| Archetype | Key signal | Template |
|-----------|-----------|----------|
| **Physical-world / Hardware + Data** | A physical asset is deployed; data from that asset is the recurring revenue driver | `references/dna-physical-world.md` |
| **B2B2C Marketplace** | An institution (employer, insurer, government) pays on behalf of an individual end user who consumes a third-party product or service | `references/dna-b2b2c-marketplace.md` |
| **Two-sided Marketplace** | Buyers and sellers are both voluntary market participants transacting directly; the platform earns a rake on their exchange | `references/dna-two-sided-marketplace.md` |
| **SaaS / B2B Platform** | A business buys software to automate workflows or generate intelligence; value is the software, not liquidity or a physical asset | `references/dna-saas-platform.md` |
| **None of the above** | Model spans archetypes, is genuinely novel, or doesn't fit cleanly | `references/dna-generic.md` |

If the model spans two archetypes (e.g., a B2B2C marketplace with SaaS tooling sold
to the B-side), use the primary archetype template and note the secondary dimension
in the DNA output.

**Read the identified template before proceeding to Step 0b.**

---

## Step 0b: Extract the Seed DNA

Using the template identified in Step 0a, document the structural pattern of the seed
company across the seven dimensions in that template. This block is passed verbatim
to every research agent as their search filter.

**Do not skip or abbreviate the DNA extraction.** Agents without a precise filter
produce generic lists. Agents with one produce targetable analogs.

After completing the extraction, explicitly state:
- Which archetype this is
- Which 2-3 dimensions are the most distinctive search filters (the ones most likely
  to surface non-obvious analogs)
- Which domains to explicitly exclude (seed company's own space)

---

## Recommended Agent Workstreams

Split the scan across two domain clusters so agents have non-overlapping search space.

### Agent 1: Domain Cluster A
Assign one cluster of physical-world domains (e.g., agriculture, construction, energy/
utilities, mining, aerial/drone inspection). Sections:

1. **Candidate scan** - Cast wide first. Name, website, domain, one-sentence description,
   business model summary. Aim for 15-25 candidates before filtering.
2. **Pattern match assessment** - Score each against the seed DNA (1-5 scale). Flag
   mismatches explicitly. Keep 3+ only.
3. **Investor roster** - For each shortlisted company: lead investors, notable co-investors,
   total raised, last round date and stage. Source from Crunchbase, PitchBook, or press.
   Every number gets an inline URL.
4. **Intro path assessment** - Shared investors with seed companies? Geographic overlap?
   University or lab connections? Conference presence?
5. **Relevance rating** - 1-5 score with one-sentence rationale per company.

### Agent 2: Domain Cluster B
Assign a different cluster (e.g., maritime, port/harbor, subsea, pipeline, bridge/road
infrastructure, environmental monitoring, insurance-adjacent sensing). Same five sections.

### Synthesis Agent
Reads both agent files. Produces one ranked, opinionated document - not a concatenation.

---

## Scoring Guide for Pattern Match Assessment

| Score | Meaning |
|-------|---------|
| 5 | Perfect DNA match - all five elements present |
| 4 | Strong match - 4+ elements; minor gaps |
| 3 | Moderate match - 3 elements; meaningful gaps |
| 2 | Weak match - 1-2 elements; structural mismatch |
| 1 | Poor match - fundamentally different model |

Shortlist companies scoring 3+. Cut the rest with a brief note on why.

---

## Output Structure for Synthesis

The synthesis follows a DIFFERENT structure than the standard thesis/findings/implications
format. Do NOT default to bullet lists or competitive positioning framing.

**CRITICAL:** The synthesis output file must begin with the document content immediately.
Do NOT include agent instructions, write protocols, or skeleton headers in the final output.
The first line of the output file must be the document title. Nothing before it.

**All seven sections below are REQUIRED.** Missing sections — especially Investor Network
Map and Recommended Next Steps — are a synthesis failure, not an optional omission.

### Required Section 1: What We Were Looking For
2-3 sentences stating the seed DNA extracted and the search logic applied. Name the
archetype identified. State the 2-3 dimensions that drove the analog search.

### Required Section 2: Top Analogs
For each top-tier analog (aim for 5-8), use this exact structure:

```
### [Company Name]
**Domain:** [industry/vertical]
**What they do:** [1-2 sentences]
**Why it's a strong analog:** [1-2 sentences — specific to the seed company's situation,
  not generic "similar model" language]
**Economics:** [Revenue model, take rate or ACV, known funding/revenue figures with sources]
**Investors:** [Lead investor(s)], [co-investors] — $[X]M raised ([Source](URL))
**Intro path:** [Specific — shared investor name, geography, conference, mutual connection]
**Conversation angle:** [What to ask them; why they'd take the call; what's in it for them]
```

### Required Section 3: Where This Model Works (and Where It Doesn't)
A thematic analysis — NOT per company. 3-5 paragraphs covering:
- What market/structural conditions make this model succeed
- Where it has failed, with named examples and what specifically broke
- What the pattern of failure reveals about the model's limits
This section must name specific companies and specific failure mechanisms, not generic risks.

### Required Section 4: Themes and Groupings
Identify 3-5 structural themes or archetypes across the analog set. Each theme should
have a name, 2-3 sentences explaining the pattern, and 2-3 example companies.
This is the "what do they have in common" section — the patterns that explain
why certain analogs work and others don't.

### Required Section 5: Second-Tier Analogs
Briefer entries for companies that scored 3/5 on pattern match. For each: name, domain,
one sentence on fit, funding (if known), intro path.

### Required Section 6: Investor Network Map
**This section is non-optional.** Identify the 3-5 investors who appear most frequently
across the shortlisted analog companies. For each: investor name, which analogs they've
backed, and why they're a high-leverage intro node. The goal is to identify the shortest
path to warm introductions — this is often through one or two investors who have backed
multiple analogs.

### Required Section 7: Recommended Next Steps
5-7 specific, ordered actions. For each: who to contact, through whom (specific warm
path), what the ask is, and why this conversation is worth having now. Order by
reachability × relevance, not just relevance alone.

---

## Key Data Sources

- **Crunchbase** - Funding rounds, investor rosters, founding dates, total raised
- **PitchBook** - Deeper investor data, valuation estimates (may require access)
- **LinkedIn** - Headcount, leadership, founder backgrounds, shared connections
- **Company websites** - Product detail, customer names, positioning, case studies
- **TechCrunch / The Information** - Funding announcements, strategic context
- **Domain-specific trade press** - Surfaces companies not yet on Crunchbase
- **AngelList / Wellfound** - Early-stage companies not yet on Crunchbase

---

## Common Pitfalls

- **Skipping the DNA extraction step.** Agents without a precise pattern produce generic
  lists. The extraction step is not optional.
- **Confusing analogs with competitors.** If a company would appear in a competitive
  analysis, it's probably the wrong call.
- **Treating investor data as complete.** Crunchbase is often incomplete, especially for
  seed/pre-seed. Note confidence level on investor data where uncertain.
- **Ranking only on relevance, ignoring reachability.** A 5/5 analog with no warm intro
  path may be less actionable than a 3/5 with a shared lead investor.
- **No "why they'd take the call" angle.** An intro without a value proposition for the
  other party is just a cold email with extra steps.
