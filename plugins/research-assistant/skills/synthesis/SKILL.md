---
name: synthesis
description: >
  Synthesis skill for combining multiple research agent outputs into a single coherent
  prose document. Handles cross-cutting themes, contradictions, confidence assessment,
  and type-specific output formats. Used by the research orchestrator after research
  agents complete. Not directly invoked by users.
user-invocable: false
---

# Synthesis — Research Output Consolidation

This skill handles Phase 5 of the research workflow: reading all research agent output
files and producing a single coherent synthesis document. The synthesis is organized
by theme, not by agent - the reader should never know how many agents contributed.

---

## Core Workflow

1. Read ALL research agent output files
2. Read all internal findings from Phase 0
3. Identify cross-cutting themes, contradictions, and gaps
4. Produce a single coherent **prose-first document** (not bullets)
5. Follow the write protocol (write after every read)
6. Match the communication style preferences from company context

**CRITICAL: Clean output only.** The synthesis output file is the final deliverable.
It must begin with the document title on line 1. Do NOT include:
- Write protocol instructions
- Agent skeleton headers or Status lines
- "CRITICAL INSTRUCTIONS FOR SYNTHESIS AGENT" blocks
- Any meta-commentary about the synthesis process itself

If the synthesis file was created with a skeleton that includes instructions,
REPLACE the entire file content with the clean document. The reader should see
a polished research document, not an agent's work log.

---

## Standard Synthesis Structure

Unless the research type specifies a different format (see Type-Specific Overrides
below), every synthesis follows this structure:

1. **Opening thesis** - 2-3 sentences stating the key finding or recommendation.
   Take a position. Don't hedge.
2. **Context** - why this question matters, what decision it informs
3. **Key findings** - organized by theme, not by agent. 3-5 themes that emerged
   from the research. Each theme gets a prose section with inline sources.
4. **Tensions and contradictions** - where sources disagree, where data conflicts,
   where the picture is unclear. Name both sides.
5. **Confidence assessment** - what's well-supported vs. what needs validation.
   Flag themes where claims rely heavily on estimates or unverified sources.
6. **Recommended next steps** - concrete and actionable. Not "continue to monitor"
   but specific actions with specific targets. 3-5 items.

---

## Type-Specific Overrides

### Analog Mapping
Follows a DIFFERENT structure than the standard format. See the analog-mapping
skill for the required output format. Key differences:
- Per-company entries with investors and intro paths
- A cross-cutting investor network map
- Ordered next steps with specific intro angles
- Do NOT default to bullet lists or competitive positioning framing

### Market Sizing
Does NOT use the standard thesis/findings structure. Market sizing has its own format:

1. **Headline number** - one sentence: "$[X] [TAM/SAM] based on [methodology]"
2. **Top-down estimate** - analyst/industry data approach with sources and FY
3. **Bottom-up estimate** - buyer universe x deal economics approach
4. **Reconciliation** - if the two approaches diverge (they usually do), explain why
   and explicitly state which number to use for decision-making and why
5. **Segment breakdown** - where is the opportunity concentrated? Table format.
6. **Key assumptions** - the 3-5 assumptions that, if wrong, change the number most.
   For each: what the assumption is, what number it affects, and what range of
   outcomes results from changing it
7. **Implications** - what the sizing means for the specific decision at hand

Do NOT bury the headline number. The first sentence of the document states the
number and methodology. Everything after is the evidence and reasoning.

### Competitive Analysis
Does NOT use the standard thesis/findings structure. Competitive analysis has its own
format:

1. **Competitive thesis** - 2-3 sentences: what's the overall dynamic, who's winning,
   and what's shifting? Take a position.
2. **Market structure** - how many serious players? How are they segmented?
   (Direct competitors, indirect, and adjacent - explicitly categorized)
3. **Competitor profiles** - prose, one paragraph per competitor covering: product,
   customers, momentum (growing/flat/declining, with evidence), recent moves,
   and how they compare to the company being analyzed. **Momentum is required:**
   every profile must state trajectory with evidence (funding, hiring, churn,
   market share trend), not just current state.
4. **Positioning matrix** - a 2x2 or table showing how each competitor is
   differentiated. Choose the two axes that matter most for THIS market.
   Common axis pairs: enterprise vs. SMB + platform vs. point solution;
   price vs. depth; self-serve vs. high-touch. Name the axes explicitly.
5. **Competitive position assessment** - where the company wins, where it's exposed,
   what's defensible, what's at risk. Prose, not bullets.
6. **Strategic implications** - specific actions. "Monitor X" is not acceptable.
   "Invest in Y because competitor Z is closing the gap on feature W" is.

### Build/Buy/Partner
Does NOT use the standard thesis/findings structure. B/B/P has its own format:

1. **Recommendation** - one sentence, up front. "Build," "Buy [Target]," "Partner
   with [Vendor]," or "Do nothing" - stated clearly before the analysis.
2. **Capability gap** - what problem are we solving and why it matters NOW vs. later
3. **Do nothing option** - always evaluated first. What happens if we don't address
   this gap? Is it actually acceptable? Sometimes it is.
4. **Build option** - realistic timeline, cost (people x months), and the 2-3 risks
   that matter. Not a strawman.
5. **Buy option** - 2-3 named targets with deal size estimates, or "no viable targets
   exist" with reasoning. Include integration risk.
6. **Partner option** - 2-3 named partners, what the arrangement looks like, dependency
   risk, and what happens when the partner's interests diverge from ours
7. **Trade-off matrix** - table: Option | Time | Cost | Risk | Control | Best when...
8. **Rationale** - why the recommendation wins over the alternatives

### Industry & Trend
Does NOT use the standard thesis/findings structure. Industry trend has its own format:

1. **Directional thesis** - 2-3 sentences: where is this market heading in the next
   2-3 years? Take a position, with a time horizon attached.
2. **What's actually moving** - the 2-4 forces that are genuinely reshaping the market
   RIGHT NOW, with evidence. Distinguish from noise (see signal-vs-noise criteria
   in the industry-trend skill).
3. **What's being overhyped** - 1-2 trends that get disproportionate coverage relative
   to their actual impact on the market. Name why the hype exceeds the reality.
4. **Buyer behavior shifts** - what are practitioners and buyers actually doing
   differently? Earnings call evidence, survey data, adoption numbers.
5. **Vendor landscape shift** - who's growing, who's contracting, what strategic moves
   signal where the market is headed
6. **The 2-3 year trajectory** - where does this converge? What does the market look
   like in 2028? Be specific.
7. **Implications for [company]** - what does this mean for the company's product,
   positioning, hiring, or investment? Specific actions, not "stay aware of trends."

### Company Financial Analysis (Public Companies)
Uses the structured earnings report format defined in the company-financials
skill. This is more structured than typical synthesis - includes specific
sections for Revenue, Profitability, Key Metrics table, Valuation, Strategic
Observations, Growth Triggers, and Walk the Talk.

### Company Deep Dive
Follows the 10-section structure defined in the company-deep-dive skill.
Agent 4 (Scenarios) functions as a mini-synthesis that reads the other three
agents' outputs. The final document maintains the section ordering, not a
thematic reorganization.

### Technology Landscape
Does NOT use the standard thesis/findings structure. Technology landscape has its own
format:

1. **Category thesis** - 2-3 sentences: what is this category, what's its current state,
   and what should a buyer know before evaluating?
2. **Category map** - all vendors organized by segment or tier. Table format.
3. **Vendor profiles** - one paragraph per major vendor (top 5-8) covering capabilities,
   target buyer, maturity classification (Emerging/Growing/Mature/Declining), and key
   strengths/limitations.
4. **Feature comparison matrix** - table: vendors across rows, key capabilities across
   columns. Use clear indicators (strong/adequate/weak/absent).
5. **Maturity landscape** - table showing where each vendor sits on the maturity curve
   with evidence for the classification.
6. **Recommendations** - tailored to the company's context. "If your priority is X,
   evaluate Y first." Specific, not generic.

### Regulatory Landscape
Does NOT use the standard thesis/findings structure. Regulatory landscape has its own
format:

1. **Regulatory thesis** - 2-3 sentences: what's the overall regulatory posture for
   this space? Heavily regulated, lightly regulated, or in transition?
2. **Regulatory map** - which bodies regulate what, and under which frameworks.
   Table format for multi-jurisdiction.
3. **Key requirements** - prose description of the 3-5 most important regulatory
   requirements. For each: what it requires, who it applies to, certainty level
   (ENACTED/FINAL RULE/PROPOSED/EXPECTED/SPECULATIVE).
4. **Compliance burden summary** - table: regulation x burden dimensions (cost, time,
   expertise, maintenance, business impact). Rated Low/Medium/High.
5. **Regulatory direction** - what's changing? Pending legislation, enforcement trends,
   likely trajectory over 1-3 years.
6. **Strategic implications** - what does this mean for market entry, product design,
   or competitive position? Specific actions.

### Due Diligence
Does NOT use the standard thesis/findings structure. Due diligence has its own format:

1. **Verdict** - first sentence. Go, conditional go, or no-go. With one-line rationale.
   Do NOT bury this.
2. **Deal thesis recap** - what was the hypothesis? 2-3 sentences.
3. **Thesis validation** - what does the evidence say? Is the thesis supported,
   partially supported, or undermined?
4. **Business summary** - what the company does, how it makes money, what's defensible.
   One paragraph.
5. **Financial snapshot** - key numbers: revenue, growth, margins, burn, runway.
   Table format.
6. **Risk assessment** - the Risk Scoring Matrix (market, product, team, financial,
   competitive, legal/IP, integration) with explanations for all HIGH risks.
7. **Deal breaker flags** - any items from the deal breaker checklist that are flagged,
   with explanation. Run the full checklist even if the company looks strong.
8. **Key questions for next phase** - 3-5 specific items that must be verified before
   finalizing the decision.

### Person Profile
Does NOT use the standard thesis/findings structure. Person profile has its own format:

1. **One-line summary** - who is this person in one sentence? Role, organization,
   and what they're known for.
2. **Career narrative** - 2-3 paragraphs telling the story of their career. Not a
   resume - a narrative that explains how they got where they are and what drives them.
3. **What they care about** - based on their public voice: key topics, positions,
   and priorities.
4. **Network and influence** - key affiliations, board seats, investment activity,
   and who they're connected to that matters for the user's context.
5. **Recent activity** - what they've been doing in the last 6 months.
6. **Meeting prep brief** - (if context is meeting prep) structured brief with:
   3 things to know, conversation starters, watch-for notes, and don'ts.
7. **Open questions** - what we couldn't find or verify.

### Ecosystem Map
Does NOT use the standard thesis/findings structure. Ecosystem map has its own format:

1. **Ecosystem thesis** - 2-3 sentences: what is this ecosystem, how is it structured,
   and where does power sit?
2. **Ecosystem map** - organized by player category. For each category: key players,
   their role, scale, and power classification (Dominant/Influential/Participant/Dependent).
3. **Value chain** - how value flows through the ecosystem. Who pays whom, where margin
   concentrates, where bottlenecks exist.
4. **Relationship map** - key partnerships and dependencies. Organized by relationship
   type with depth, stability, and exclusivity assessed.
5. **Power analysis** - who controls what, and what that means for new entrants or
   participants trying to grow their position. Evidence for each power classification.
6. **Strategic implications** - specific partnership targets, ecosystem risks, and
   recommended positioning.

---

## Writing Rules (Non-Negotiable)

These apply to every synthesis regardless of research type.

- **Prose-first.** Never bullets for analysis or argument. Bullets only for
  genuinely enumerable items (lists of competitors, feature comparisons).
- **No corporate jargon.** Synergies, robust, holistic, value-added, end-to-end
  solutions, leveraging - none of it. Write plainly.
- **No superlatives without a verifiable source.** "Leading player," "best-in-class,"
  "market leader" - only if a source backs it up. Otherwise, describe what the
  company actually does.
- **No em dashes.** Use regular dashes (-).
- **Every quantitative claim needs an inline source URL.** No orphaned facts.
- **Blockquotes for direct quotes only.** Use when a management statement is specific,
  datable, and adds something the paraphrase can't. Not as routine decoration.
- **Tables serve comparison, not decoration.** Use when comparing 3+ items across
  multiple attributes where prose would be confusing. Skip when prose works fine.
- **No length padding.** Every sentence must add genuine understanding. Cut filler
  ruthlessly.
- **End with concrete implications.** Not "this is worth watching" but specific
  actions, decisions, or questions that the research answers or raises.

---

## Length Discipline

Target synthesis lengths by type. These are guidelines, not hard caps — a complex
market with 6 competitors needs more space than a simple one with 2. But exceeding
the range should be intentional, not accidental padding.

| Research Type | Target Length | Notes |
|--------------|--------------|-------|
| Competitive Analysis | 150-250 lines | One paragraph per competitor, not three |
| Industry & Trend | 100-175 lines | Tighter = more opinionated |
| Market Sizing | 80-150 lines | The math speaks; don't narrate around it |
| Build/Buy/Partner | 100-175 lines | Recommendation + evidence, not exhaustive |
| Analog Mapping | 150-250 lines | Per-company entries add up; that's fine |
| Company Deep Dive | 300-600 lines | Depth mandate applies; this type runs long by design |
| Company Financial Analysis | 150-300 lines | Structured format keeps it focused |
| Technology Landscape | 150-250 lines | Feature matrix + maturity curve add structure |
| Regulatory Landscape | 150-250 lines | Jurisdiction matrix adds length; keep prose tight |
| Due Diligence | 200-350 lines | Comprehensive by nature; verdict + risk flags required |
| Person Profile | 80-150 lines | Focused brief; depth on track record, not biography |
| Ecosystem Map | 150-250 lines | Per-player entries add up; cross-cutting themes required |

### Signs of padding (cut these):
- M&A speculation sections the user didn't ask for
- "Recommended positioning statement" blocks
- Appendix tables that duplicate the prose
- Research methodology sections (the reader doesn't need to know how many agents ran)
- Executive summaries that repeat the opening thesis
- "Conclusion" sections that restate the implications

---

## Common Pitfalls

- **Organizing by agent instead of by theme.** The reader doesn't care which agent
  found what. Reorganize by theme.
- **Concatenation instead of synthesis.** Putting three agent outputs end-to-end
  is not synthesis. Find the cross-cutting insights.
- **Burying contradictions.** Tensions between sources are often the most valuable
  insight. Surface them, don't resolve them artificially.
- **Hedging the thesis.** The opening thesis should take a position. If the evidence
  doesn't support a clear position, say that - but still state the most likely
  interpretation.
- **Generic next steps.** "Further research needed" is never an acceptable next step.
  Be specific about what to research, who to ask, and why.
