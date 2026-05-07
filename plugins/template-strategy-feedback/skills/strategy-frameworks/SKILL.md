---
name: strategy-frameworks
description: >
  Apply proven strategy frameworks to any company's decisions. Includes 14 frameworks
  across advantage analysis, product strategy, growth sequencing, decision-making,
  and synthesis. Trigger on: "apply a framework", "run 7 Powers on", "use Porter's on",
  "framework:", "what framework should I use for", "analyze this using", "Minto this",
  "MECE this", "structure this argument", or any request to apply a structured
  analytical lens to a strategic question. When in doubt, load it.
---

# Strategy Frameworks Skill

This skill routes you to the right analytical framework for any strategic question and walks you through applying it systematically.

## Framework Directory

| Category | Frameworks | Use When |
|----------|-----------|----------|
| **Advantage** | 7 Powers, Porter's Five Forces, Aggregation Theory, Moats & Flywheels, Leaky Bucket | "Where's the advantage? Is it durable?" |
| **Product** | Jobs to Be Done, Blue Ocean / Value Curve | "What should we build? How should we position it?" |
| **Growth** | Crossing the Chasm, SaaS vs. Marketplace, Reverse-Engineered P&L | "How do we grow? Does the math work?" |
| **Decision** | Disruptive Innovation, Three Horizons, MECE Issue Trees | "How do we decide? How do we allocate?" |
| **Synthesis** | Minto Pyramid Principle | "How do we structure the argument?" |

## Application Workflow

When triggered:

1. **Identify the framework(s)** - If the user specifies a framework, load it. If they describe a problem, recommend the best framework and explain why.

2. **Load the reference** - Retrieve the relevant reference file(s) from the `references/` directory.

3. **Load competitive intel (REQUIRED)** - Before applying any framework:
   - Identify the target company using the competitive-intel skill's multi-company routing logic
   - Load that company's reference files: `competitive-landscape.md`, `strategic-decisions.md`, and `market-context.md`. These provide the grounding data that prevents generic analysis.
   - If no company is configured, note that the analysis will be more generic and recommend setting up company context.
   - Then search Glean, Slack, and the web for additional context specific to the question.
   - Do NOT skip this step. Framework analysis without competitive and strategic grounding produces generic output that could apply to any company.

4. **Apply systematically** - Work through EVERY dimension/step. Don't skip or summarize. The value is in the structured completeness.

5. **Stress-test against competitive reality** - After applying the framework, explicitly test your conclusions against the competitive landscape and market context:
   - Does a competitor's position challenge or confirm this conclusion?
   - Do buyer behavior shifts strengthen or weaken this finding?
   - Could an emerging threat (merger, new entrant, PE activity) invalidate this within 12 months?
   - If you're claiming the company has an advantage, name the specific competitor or alternative that makes this advantage hard to hold.

6. **Output the analysis** - Present findings organized by the framework's dimensions, with clear reasoning at each step. Include a "Competitive Reality Check" section at the end that summarizes how competitive data supports or challenges the key findings.

## Key Guidance

**MECE vs. Other Frameworks:**
- Use **MECE** when you need to decompose an ambiguous question BEFORE applying another framework
- Use **Minto** when you need to structure your conclusion AFTER analysis is complete
- The other 12 are analytical lenses - apply them directly to the question

**Combo Recommendations:**
For a full strategic analysis of a new product bet, consider:
1. MECE to decompose the question into clean sub-questions
2. 7 Powers + Crossing the Chasm for advantage and adoption analysis
3. Reverse-Engineered P&L for financial validation
4. Minto to structure the recommendation

For a competitive positioning decision:
1. Porter's Five Forces for market structure
2. Blue Ocean for differentiation mapping
3. 7 Powers to validate defensibility
4. Minto to articulate the strategy

For a platform/marketplace bet:
1. Aggregation Theory for demand/supply dynamics
2. Leaky Bucket for network effect defensibility
3. SaaS vs. Marketplace diagnosis
4. Reverse-Engineered P&L for unit economics
5. Minto for the strategic case

## Application Example

**User asks:** "Should we build a direct-to-consumer product or go deeper with enterprise?"

**Your approach:**
1. Recommend MECE to decompose the decision (market size, competitive positioning, unit economics, strategic alignment)
2. Then apply Aggregation Theory to evaluate demand/supply control in each path
3. Use Three Horizons to consider timing and resource allocation
4. Validate with Reverse-Engineered P&L on each path
5. Structure the recommendation with Minto

## Framework Reference Files

All frameworks are documented in `references/`:

- `seven-powers.md` - Hamilton Helmer's 7 Powers
- `porters-five-forces.md` - Porter's Five Forces
- `aggregation-theory.md` - Ben Thompson's Aggregation Theory
- `moats-and-flywheels.md` - Moats & Flywheels
- `leaky-bucket.md` - Dan Hockenmaier's Leaky Bucket Theory
- `jobs-to-be-done.md` - Clayton Christensen's Jobs to Be Done
- `blue-ocean-value-curve.md` - Blue Ocean / Value Curve Analysis
- `crossing-the-chasm.md` - Geoffrey Moore's Crossing the Chasm
- `saas-vs-marketplace.md` - Casey Winters' SaaS-like Network vs. True Marketplace
- `reverse-engineered-pl.md` - Reverse-Engineered P&L
- `disruptive-innovation.md` - Clayton Christensen's Disruptive Innovation
- `three-horizons.md` - McKinsey's Three Horizons Framework
- `mece-issue-trees.md` - MECE Issue Trees
- `minto-pyramid.md` - Barbara Minto's Pyramid Principle

Each file is a substantive analytical tool with application guidance and common mistakes.
