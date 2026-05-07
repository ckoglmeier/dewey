---
name: build-buy-partner
description: >
  Evaluate build vs. buy vs. partner decisions - capability gaps, M&A targets, partnership
  options. Use when someone asks "should we build or buy", "evaluate M&A targets for",
  "partnership options for", "how should we fill this capability gap", or any strategic
  make-or-buy decision. Can be invoked directly or via the research orchestrator.
---

# Build / Buy / Partner Research Type

**Standalone execution:** If invoked directly (not via the research orchestrator),
follow the protocol in `../research/references/standalone-execution.md` to run the
full pipeline: company context → internal recon → plan → launch agents → monitor →
synthesize.

Use this type when the research question is about a strategic capability decision -
whether to build something internally, acquire a company, or partner with an external
provider.

---

## When to Use This Type

- "Should we build or buy [capability]?"
- "What companies could we acquire for [X]?"
- "Who should we partner with for [capability/market]?"
- "Is there an M&A target that could accelerate [initiative]?"
- "What would it cost/take to build [feature] vs. licensing it?"
- "Evaluate [company] as a potential acquisition or partner"

---

## Recommended Agent Workstreams

For most build/buy/partner questions, plan 3 agents:

**Agent 1: Problem and Capability Definition**
Sections:
1. What capability gap is being addressed? - Define the problem precisely; what does
   the company need to do that it can't do well today?
2. Why this capability matters strategically - what does it unlock for the product,
   customers, or competitive position?
3. What "good" looks like - if the company had this capability fully, what would be
   different? What's the measurable outcome?
4. Urgency and timing - how quickly is this needed? What's the cost of delay?

**Agent 2: Build Option Analysis**
Sections:
1. What building entails - technical scope, product requirements, team/resources needed
2. Timeline to meaningful capability - realistic estimate, including ramp time
3. Cost estimate - engineering, product, and operational costs (order of magnitude)
4. Risks and dependencies - what could go wrong? What does this depend on?
5. Precedents - has a comparable company built something like this before? What happened?

**Agent 3: Buy and Partner Option Analysis**
Sections:
1. Acquisition target landscape - which companies have the capability needed? 2-5
   candidates with brief profiles
2. For each target: product maturity, customer base, team quality,
   funding/valuation, and strategic fit
3. Estimated deal size and integration complexity
4. Partner option landscape - which companies could be partnered with instead?
5. Partnership economics and dependency risks - what would a partnership look like?
   What does the company give up by not owning it?

---

## Decision Rigor Framework (REQUIRED)

Every build/buy/partner analysis must apply structured rigor to prevent the three most
common failure modes: (1) strawmanning the build option to justify a buy, (2) ignoring
the do-nothing option, (3) underestimating partnership dependency risk.

### Switching Cost Reality Check

For each option (build, buy, partner), explicitly answer:
- **What are we locked into if we choose this?** — Sunk costs, contractual commitments,
  team reorgs, customer migration paths.
- **What does it cost to reverse this decision in 18 months?** — If we build and it
  doesn't work, how much did we lose? If we buy and integration fails? If we partner
  and the vendor pivots?
- **Is this a one-way or two-way door?** — Two-way doors (easily reversible) deserve
  less deliberation. One-way doors (acquisitions, multi-year platform commitments)
  deserve more.

### Time-to-Value Honesty

The most common bias in B/B/P analysis is overestimating build timelines and
underestimating buy integration timelines:

- **Build timeline** — Engineering estimates are 2-3x optimistic. Always apply a
  multiplier and explain it. If engineering says "6 months," model for 12-18 months
  including hiring, ramp, iteration, and edge cases.
- **Buy timeline** — "Close in 3 months" ignores due diligence (2-4 months),
  integration (3-12 months), team retention risk (50% of acquired engineers leave
  within 18 months industry average), and product migration. Total time to
  functioning capability: typically 9-18 months post-close.
- **Partner timeline** — Fastest to initial capability (weeks to months). But "up and
  running" is not "fully integrated." Budget for integration, customization, and the
  ongoing relationship management cost.

State realistic timelines for each, with the assumptions that drive them.

### Partnership Dependency Stress Test

For any partner option, answer these three questions:

1. **What happens if the partner gets acquired?** — New parent may change pricing, kill
   the product, or compete with us. How exposed are we?
2. **What happens if the partner raises prices 3x at renewal?** — Do we have leverage?
   Is there an alternative? How embedded are they in our product?
3. **What happens if we outgrow the partner?** — Can we migrate away? What's the data
   portability story? Do we lose capability during transition?

If the answer to any of these is "we'd be in serious trouble," the partner option
carries more risk than it appears on the surface.

### Do-Nothing Evaluation

The do-nothing option is not "do nothing forever." It's "don't address this now."
Evaluate it honestly:

- **What's the actual cost of delay?** — Be specific. "We lose competitive advantage"
  is not specific. "Competitor X launches Y feature in Q3 and our win rate in the
  [segment] drops from Z% to W%" is specific.
- **Is this capability urgent or important?** — Urgent + important = address now.
  Important but not urgent = address in 6-12 months. Not important = don't address.
- **What could we learn by waiting?** — Sometimes the market hasn't settled enough to
  make a good build/buy/partner decision. Waiting 6 months might reveal which vendor
  wins, what the real requirements are, or whether the need was overstated.

---

## Decision Framework

After research is complete, the synthesis should apply this framework:

| Dimension | Build | Buy | Partner |
|-----------|-------|-----|---------|
| Speed to capability | Slowest | Fast | Fast |
| Cost | High (long-term labor) | High (upfront capital) | Lower (but ongoing fees) |
| Strategic control | Full | Full | Limited |
| Integration risk | Low | High | Low |
| Best when... | Core differentiation; already close | Time pressure + right target exists | Non-core; vendor is better + stable |

**Things to always address:**
- Does this capability represent core differentiation, or is it table stakes?
- What's the real urgency? A 2x speed advantage from buying vs. building only matters
  if the window is actually closing.
- Partnership dependency risk: "We can always build it later" is often wrong once a
  vendor is embedded in the product.
- The "do nothing" option: sometimes the capability gap isn't worth addressing yet.
  Name this option and evaluate it.

---

## Key Data Sources

- **Crunchbase / PitchBook** - acquisition target valuations, funding history
- **LinkedIn** - team size, engineering headcount at target companies; helps estimate
  build cost
- **Company websites and documentation** - product maturity, API/integration capabilities
- **G2 / Gartner** - product reviews; useful for gauging maturity and customer
  satisfaction of buy/partner targets
- **M&A comparables** - recent deals in the relevant sector (look for revenue multiples)
- **Job postings** - what a company is actively building; hints at roadmap

---

## Output Structure for Synthesis

1. **Recommendation up front** - one clear thesis. Don't bury the lede.
2. **Capability gap** - what problem are we solving and why it matters now
3. **Build option** - realistic assessment of timeline, cost, and risk; not a strawman
4. **Buy option** - 2-3 specific targets with profiles and deal size estimates; or
   "no viable targets exist" if that's the finding
5. **Partner option** - 2-3 specific partners; what partnership would look like;
   dependency risks
6. **Trade-off analysis** - what does each option cost in time, money, risk, and
   strategic control?
7. **Recommendation and rationale** - restate with key reasons; address the strongest
   counterargument
8. **Next steps** - specific actions (e.g., "reach out to [target] for exploratory
   conversation", "scope a 6-week engineering spike")

---

## Common Pitfalls

- **False precision on build costs:** Engineering estimates are notoriously optimistic.
  Build in a 2-3x buffer and be transparent about it.
- **Falling in love with an acquisition target:** Make sure the analysis is honest about
  integration risk and whether the team/culture will stick.
- **Underestimating partnership dependency:** Flag explicitly what happens if the partner
  gets acquired, pivots, or raises prices.
- **Missing the "do nothing" option:** Sometimes the right answer is that the capability
  gap isn't worth addressing yet. Name it and evaluate it using the Do-Nothing
  Evaluation framework.
- **Strawmanning the build option:** Inflating build timelines or complexity to make
  buy look better. Apply the 2-3x multiplier honestly, but don't make build look
  impossible when it's just slower.
- **Ignoring post-acquisition integration reality:** "Buy" sounds fast, but integration
  takes 9-18 months. 50% of acquired engineers leave within 18 months. Factor real
  integration timelines into the comparison.
- **Partnership as the easy middle ground:** Partnership often looks like the low-risk
  option but creates hidden dependency. Run the Partnership Dependency Stress Test
  on every partner option.
