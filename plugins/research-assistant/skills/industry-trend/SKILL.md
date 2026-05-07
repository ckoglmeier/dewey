---
name: industry-trend
description: >
  Research industry trends and market dynamics - what's shifting, what's signal vs. noise,
  where the market is heading. Use when someone asks "what's happening in [market]", "how
  is [technology] changing", "what are the trends in [space]", "what's the state of
  [industry]", or any request to understand market forces and direction. Can be invoked
  directly or via the research orchestrator.
---

# Industry & Trend Research Type

**Standalone execution:** If invoked directly (not via the research orchestrator),
follow the protocol in `../research/references/standalone-execution.md` to run the
full pipeline: company context → internal recon → plan → launch agents → monitor →
synthesize.

Use this type when the research question is about understanding how a market,
technology, or behavior is shifting - not sizing it or comparing specific competitors,
but making sense of the forces at play and what they mean for the company.

**Choosing between State Landscape and Industry & Trend:** State Landscape asks
"how does this specific state's workforce system work?" Industry & Trend asks
"what's happening in a market or technology area?" If the question is "tell me
about Tennessee's workforce system," that's State Landscape. If the question is
"what's happening in workforce development technology," that's Industry & Trend.

---

## When to Use This Type

- "What's happening in [market/technology area]?"
- "How are [buyers] thinking about [topic] right now?"
- "What's the state of [industry] post-[major event]?"
- "How is [technology] changing the [space]?"
- "What are the big trends shaping [market]?"
- "What's [buyer type] sentiment on [topic] right now?"
- "Pull together what's happening with [trend/theme]"

---

## Recommended Agent Workstreams

For most industry and trend research, plan 2-3 agents:

**Agent 1: Landscape & Macro Forces**
Sections:
1. The current state of the market - what's happening right now? Who's investing,
   who's pulling back, and why?
2. Macro forces driving change - economic, demographic, regulatory, and technological
   tailwinds and headwinds
3. Key tensions in the market - what are the debates? Where do smart people disagree?
4. Recent notable events - funding rounds, acquisitions, product launches, policy
   changes, or research in the last 12-18 months that signal where the market is heading

**Agent 2: Signal Synthesis (Buyer, User, and Provider Perspectives)**
Sections:
1. What buyers are saying and doing - survey data, earnings call commentary, industry
   reports; what are they prioritizing and defunding?
2. What end users want - user/consumer sentiment, engagement data, what's driving
   adoption or abandonment
3. What vendors and providers are doing - how are incumbents and startups adapting?
   What's growing, what's contracting?
4. Analyst and expert views - what are the credible voices saying? Where is consensus
   forming vs. where is it fractured?

**Agent 3: Implications** (can be the synthesis agent rather than a separate research agent)
Sections:
1. The 2-3 year trajectory - where is this heading?
2. Opportunities this creates - what trends play to the company's strengths?
3. Threats and risks - what trends create headwinds for the current model?
4. Strategic questions this raises - what decisions does the company need to make?

---

## Key Data Sources

### General
- **Industry analyst firms** - Gartner, Forrester, IDC, McKinsey Global Institute
- **CB Insights** - tech trend reports, funding data
- **Crunchbase** - funding trends signal where capital is going

### Buyer / Practitioner Sentiment
- **Professional association surveys** - most industries publish annual benchmarking
- **LinkedIn Workforce Report** - hiring trends, skill demand shifts
- **Earnings call transcripts** - public company executives often give the best
  unfiltered view of market conditions

### Market / Technology Trends
- **Trade press** - sector-specific publications
- **Vertical analyst firms** - many industries have specialized research firms
- **Gartner Hype Cycle** - technology maturity assessments (may be paywalled)
- **arXiv / academic preprints** - for technology trend research, especially AI/ML

---

## Signal vs. Noise Framework (REQUIRED)

Every trend identified by research agents must be assessed through this filter before
the synthesis. This prevents the output from treating press coverage as market reality.

### Three-tier classification:

**SIGNAL (include and weight heavily):**
- Backed by behavioral evidence: hiring data, funding rounds, earnings call guidance,
  adoption metrics, market share shifts
- Multiple independent sources confirm the same direction
- Has a specific time horizon and measurable indicator attached
- Practitioners are changing behavior, not just talking about it

**NOISE (include but explicitly label as overhyped):**
- Backed primarily by vendor marketing, conference hype, or aspirational survey data
- One dominant narrative source (e.g., a single Gartner report) without independent
  confirmation
- "74% of buyers say they plan to invest in X" — stated intent without behavioral follow-through
- VC funding flowing in but no corresponding buyer adoption or revenue traction

**TOO EARLY TO TELL (include with explicit uncertainty):**
- Genuine technological or market shift, but adoption evidence is <12 months old
- Academic/research community consensus forming but commercial application untested
- Policy/regulatory change announced but not yet implemented or enforced

Agents must classify EVERY trend they surface into one of these three tiers.
The synthesis must reflect this classification — Signal trends get the most space,
Noise trends get explicitly called out as overhyped, and Too Early trends get
flagged with "here's what to watch for in 6-12 months."

---

## Temporal Framing (REQUIRED)

Every finding must carry a time horizon. "X is happening" is not acceptable without
specifying when.

### Four time horizons:

- **Now (0-6 months):** Actively occurring. Evidence: current quarter earnings, active
  hiring, shipped products, signed contracts. Use present tense.
- **Near-term (6-18 months):** Strong evidence of direction but not yet arrived.
  Evidence: announced roadmaps, funded initiatives, regulatory timelines. Use future
  tense with confidence.
- **Medium-term (2-3 years):** Directional thesis supported by trend lines, but
  prediction uncertainty is real. Evidence: demographic shifts, technology maturity
  curves, investment patterns. State the thesis and the key assumption that must hold.
- **Structural (3-10 years):** Secular shifts. Evidence: demographic inevitability,
  infrastructure buildout, regulatory entrenchment. Name the structural force and
  what would reverse it.

Agents must tag every trend with one of these horizons. The synthesis must organize
findings by time horizon — what's happening now is more actionable than what might
happen in five years. A trend without a time horizon is not a finding.

---

## Source Credibility Hierarchy

When agents find conflicting signals (which they should), apply this hierarchy to
determine which source to weight more heavily:

1. **Primary behavioral data** (what people are doing): earnings results, adoption
   metrics, hiring data, market share — highest credibility
2. **Earnings call guidance** (what management is committing to): forward-looking
   statements by public company executives with fiduciary obligation — high credibility
3. **Independent research** (what analysts found): analyst reports not funded by a
   vendor in the space — moderate credibility
4. **Survey data** (what people say they'll do): stated intent without behavioral
   confirmation — low credibility for prediction, useful for sentiment only
5. **Vendor/conference content** (what sellers are promoting): whitepapers, keynotes,
   press releases — lowest credibility as trend evidence; useful only for understanding
   what vendors believe the market will buy

When a survey says buyers will do X but earnings data shows they're doing Y, the
earnings data wins. Always.

---

## Output Structure for Synthesis

The synthesis follows the Industry & Trend format specified in the synthesis skill.
Key sections:

1. **Directional thesis** (2-3 sentences): Where is this market heading? Include
   time horizon. Take a position.
2. **What's actually moving (SIGNAL)**: The 2-4 forces reshaping the market NOW,
   each with behavioral evidence, time horizon, and source credibility tier.
3. **What's being overhyped (NOISE)**: 1-2 trends getting disproportionate coverage.
   Name WHY the hype exceeds reality.
4. **Buyer behavior shifts**: What practitioners and buyers are actually DOING
   differently. Earnings call evidence > survey data.
5. **Vendor landscape shift**: Who's growing, contracting, pivoting — and what that
   signals about where the market is heading.
6. **The 2-3 year trajectory**: Where does this converge? Be specific.
7. **Implications for [company]**: Specific actions or decisions. Not "stay aware."
8. **Open questions**: What would increase conviction? What to watch in 6-12 months?

---

## Common Pitfalls

- **Trend-listing without a thesis:** A list of 10 trends is not a synthesis. Identify
  the 2-3 that actually matter and explain why.
- **Treating survey data as ground truth:** "74% of buyers say they plan to invest in X"
  is almost always aspirational. Look for behavioral signals to cross-check.
- **Ignoring the counter-trend:** Every trend has a counter-trend. Acknowledge what's
  pushing back against the narrative.
- **Burying the implication:** The "so what for us" section should be specific and
  actionable, not hedged.
- **No time horizon:** "AI is transforming healthcare" could be happening now or in
  ten years. Specify which, and what evidence supports the timeline.
- **Treating all sources equally:** A Gartner report funded by a vendor in the space
  is not equivalent to a public company earnings call. Apply the credibility hierarchy.
- **Confusing coverage with importance:** Some trends get 10x the press coverage of
  others but have 0.1x the actual market impact. Volume of discussion is not a signal
  of importance.
