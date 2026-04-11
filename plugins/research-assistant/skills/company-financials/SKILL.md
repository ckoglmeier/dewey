---
name: company-financials
description: >
  Analyze a company's financials - earnings, revenue, margins, valuation, M&A target
  assessment. Use when someone asks "pull the financials on [company]", "earnings summary
  for", "is [company] a good acquisition target", "valuation analysis", or any request
  focused on a company's financial performance. Can be invoked directly or via the
  research orchestrator.
---

# Company Financial Analysis Research Type

**Standalone execution:** If invoked directly (not via the research orchestrator),
follow the protocol in `../research/references/standalone-execution.md` to run the
full pipeline: company context → internal recon → plan → launch agents → monitor →
synthesize.

Use this type when the research question focuses on a single company's **financial
performance, earnings results, or M&A evaluation** - profiling an acquisition target,
a strategic partner, a competitor's earnings, or any company where financials are the
primary lens.

> **Looking for deep business understanding instead?** If the goal is to truly know
> how a company works - its segments, customers, competitive position, and management
> credibility - use the company-deep-dive type instead. That type is prose-first,
> concall-driven, and contains no financial figures.

For **public companies**, the primary artifact is a quarterly earnings analysis built
from SEC filings (10-Q, 10-K), supplemented with market data and strategic context.
For **private companies**, shift to funding history, growth signals, and estimated
financials.

**Choosing between Company Financial Analysis and Business Understanding Report:**
Financial Analysis = earnings, revenue, margins, valuation, M&A math. Use when the
question is about how the company is *performing*. Business Understanding = how the
company actually works, who customers are, what management is committing to, what
could break. Use when the goal is comprehension, not evaluation. The two can be
combined - plan separate agents for each.

---

## When to Use This Type

- "Tell me everything about [company]'s financials"
- "Profile [company] as an M&A target / acquisition candidate"
- "How is [competitor] performing? What do their latest earnings say?"
- "Pull the latest 10-Q for [company] and summarize what matters"
- "What are [company]'s revenue trends and margins?"

---

## Recommended Agent Workstreams

### For Public Companies (primary path):

**Agent 1: Earnings & Financial Analysis**
Sections:
1. Topline narrative - business performance this quarter in plain English: what drove
   results, what surprised, what management emphasized
2. Revenue breakdown - total revenue, YoY growth, and by business unit/segment
3. Profitability - operating income and net income by segment; margins and YoY changes
4. Key metrics scorecard - the handful of numbers that tell the story
5. Valuation - current multiples (revenue, EBITDA), stock performance since last report
6. Management commentary - what did they say on the earnings call? What are they
   worried about / excited about?

**Agent 2: Strategic Context & Relevance**
Sections:
1. Business model overview - how the company makes money; what their core value prop
   is for each segment
2. Competitive positioning - how do they compete? Where are they gaining vs. losing?
3. Key risks and challenges - operational, competitive, regulatory, or financial risks
   called out in the filing
4. Strategic signals - M&A activity, product launches, leadership changes, expansion
5. Relevance to us - what does this mean for our company? (M&A implications,
   competitive threat/opportunity, partnership angle, market signal)

**Agent 3: Management Credibility (Walk the Talk)**
Pull the 4 most recent earnings call transcripts. Cross-reference what management
guided for vs. what actually happened.
Sections:
1. Oldest concall review - what did management guide for? What commitments were made?
2. Subsequent concalls - were commitments met? What changed and how was it explained?
3. Pattern assessment - is management consistently accurate, consistently optimistic,
   consistently conservative, or erratic?
4. Specific promises kept - with original quote and outcome
5. Specific promises missed or quietly dropped - with original quote and what happened
6. Plain-stated verdict - does this management do what they say?

**Agent 4: Growth Triggers (from concalls only)**
Extract forward-looking triggers directly from the 4 most recent earnings call
transcripts. Every trigger must be cited with the concall date and quarter.
Sections:
1. Capacity and capex triggers - new plants, expansions, capacity utilization ramps
2. Customer and market triggers - new customer wins announced, new market entries
3. Product triggers - new product launches, certifications, qualification wins
4. Timeline summary - if 6+ triggers exist, produce a table: trigger, timeline,
   concall source, status (new or repeated)

Rules for Agent 4:
- Forward-looking only. No current or past numbers.
- Every trigger must cite the specific concall: "(Q3 FY26 concall, Feb 3 2026)"
- If a trigger was mentioned across multiple concalls, note that it has been repeated
- Do not include triggers you cannot attribute to a specific concall statement
- No opinions or analysis - just what management said is coming

---

### For Private Companies (no public filings):

**Agent 1: Business & Product Profile**
Sections:
1. What the company does - product, business model, target customer, go-to-market
2. Customer base - named customers, verticals served, deal sizes if known
3. Team and leadership - founders, key executives, hiring patterns (LinkedIn headcount)
4. Product maturity - how developed is the product? Customer reviews (G2, Capterra)

**Agent 2: Financial & Growth Signals**
Sections:
1. Funding history - rounds, investors, total raised, implied valuation from last round
2. Revenue estimates - any disclosed figures, analyst estimates, or press signals
3. Growth trajectory - headcount growth, press mentions, customer announcement cadence
4. Burn and runway signals - recent fundraising, cost structure hints from job postings

**Agent 3: Strategic Fit**
Sections:
1. Capability overlap - what does this company do that our company needs or is building?
2. Integration considerations - how would this fit into our product and operations?
3. Deal size estimate - comparable transactions, typical multiples for this type of
   company
4. Build vs. buy signal - could we build this capability faster/cheaper, or is this
   the right acquisition?

---

## Output Format: Public Company Earnings Report

```
## [Company Name] - Q[X] [Year] Earnings Summary

### Topline
[2-4 sentence narrative of how the business performed. Lead with the story, not the
numbers. What drove the results? What's accelerating? What's under pressure?]

### Revenue
- **Total:** $[X]M, up [X]% YoY
- **[Segment 1]:** $[X]M, up [X]% YoY - [flat/accelerating/decelerating]
- **[Segment 2]:** $[X]M, up [X]% YoY - [characterization]

### Profitability
- **Operating income:** $[X]M total, up [X]% YoY (~[X]% of revenue)
  - [Segment 1]: $[X]M ([X]% margin)
  - [Segment 2]: $[X]M ([X]% margin)
- **Net income:** $[X]M, up [X]% YoY

### Key Metrics
| Metric | Value | YoY Change |
|--------|-------|------------|
| Revenue | $[X]M | +[X]% |
| Income from Operations | $[X]M | +[X]% |
| Operating Margin | [X]% | +[X]pp |
| Net Income | $[X]M | +[X]% |
| Cash & Equivalents | $[X]M | - |

### Valuation
- **Revenue multiple:** ~[X]x NTM revenue
- **EBITDA multiple:** ~[X]x
- **Stock performance:** [Up/Down X% since last earnings; broader characterization]

### Strategic Observations
[2-4 sentences on what this means for our company specifically. Not "this is worth
watching" - something concrete.]

### Growth Triggers (from concalls)
[Bulleted list of forward-looking triggers cited by management, each with concall date.
No triggers without a source. No opinions - just what management said.]

### Walk the Talk
[2-3 paragraph narrative on management credibility. What did they promise? Did they
deliver? What's the pattern across 4 concalls? End with a plain verdict.]
```

---

## Source Hierarchy (REQUIRED)

Not all financial data sources are equally reliable. When sources conflict, the higher-
ranked source wins. When only lower-ranked sources are available, tag claims accordingly.

### Hierarchy (highest to lowest):

1. **SEC filings (10-K, 10-Q, 8-K, S-1)** — Primary source of truth for public companies.
   Revenue, segment data, risk factors, management discussion. If a SEC filing says X
   and a press release says Y, the filing wins.

2. **Earnings call transcripts** — Direct management commentary. Use for color, guidance,
   strategic signals, and Walk the Talk analysis. Transcripts are the primary source for
   Sections 6 (Management Commentary), Walk the Talk, and Growth Triggers. Always cite
   the specific quarter: "(Q3 FY26 earnings call, Feb 3 2026)."

3. **Company investor relations materials** — Supplemental data packages, investor
   presentations, press releases with financial figures. Generally accurate but
   selectively presented (they highlight what looks good).

4. **Financial data aggregators** — Yahoo Finance, Macrotrends, Seeking Alpha, Google
   Finance. Useful for historical trends and multiples. Cross-check any figure that
   seems off against the original filing.

5. **Analyst estimates and research notes** — Forward-looking estimates, valuation
   opinions, industry comparisons. Useful for consensus view but remember analysts
   have their own incentives. Treat as informed opinion, not fact.

6. **Press and industry coverage** — TechCrunch, trade publications, business press.
   May contain leaked or estimated financials. Use for context and narrative, not as
   primary financial data source.

### For private companies:

The hierarchy shifts because SEC filings don't exist:

1. **Disclosed financials** (press releases, interviews with specific numbers) — Rare
   but highest quality when available.
2. **Crunchbase / PitchBook** — Funding rounds, implied valuations, investor data.
   Round-based valuations are snapshots, not current market values.
3. **Third-party estimates** — Growjo, Sacra, analyst estimates. Label as [ESTIMATE].
   State the estimation methodology if known.
4. **Proxy signals** — LinkedIn headcount, job postings, office expansions, customer
   announcement cadence, app store reviews, web traffic. Use to infer trajectory, not
   specific numbers.

### Labeling:
- Figures from SEC filings: no label needed (assumed accurate)
- Figures from company IR materials: no label needed if consistent with filings
- Figures from aggregators: verify against filing; if can't verify, note "(per [source])"
- Analyst estimates: always label "(analyst estimate)" or "(consensus estimate)"
- Private company estimates: always label "[ESTIMATE]" with source
- Press-sourced figures: "(per [publication], [date])" — never present as confirmed

---

## Financial Red Flags Checklist

When analyzing any company's financials, check for these common distortions and flag
them explicitly if found:

1. **Revenue recognition games** — Is revenue growing because of genuine business
   growth, or because of accounting changes (ASC 606 transitions, contract term
   changes, reclassifications)?
2. **Non-GAAP flattery** — What does the company add back to get from GAAP to non-GAAP
   earnings? Stock-based compensation, restructuring charges, and amortization of
   intangibles are the most common. If non-GAAP income is 3x GAAP income, say so.
3. **Cash flow vs. income divergence** — If net income is positive but operating cash
   flow is negative (or significantly lower), explain why. Common causes: working
   capital buildup, capitalized costs, acquisition integration.
4. **Segment margin hiding** — Is a high-margin segment subsidizing a money-losing one?
   Always break out segment-level margins when available.
5. **One-time items that recur** — "Restructuring charges" that appear every quarter
   are not one-time. Flag items the company calls non-recurring that keep recurring.
6. **Guidance sandbagging** — Does management consistently guide low and beat? This is
   fine (conservative management) but should be noted in Walk the Talk as a pattern.
7. **Debt and leverage** — What's the debt load relative to EBITDA? Is it manageable
   or concerning? Especially important for M&A target assessment.

---

## Key Data Sources

### For Public Companies:
- **SEC EDGAR** - 10-Q and 10-K filings: sec.gov/cgi-bin/browse-edgar
- **Earnings call transcripts** - Seeking Alpha, Motley Fool, or investor relations pages
- **Investor relations pages** - press releases, supplemental data packages
- **Yahoo Finance / Macrotrends** - historical financials, valuation multiples

### For Private Companies:
- **Crunchbase / PitchBook** - funding rounds, investors, valuation estimates
- **LinkedIn** - headcount, hiring patterns, leadership
- **G2, Gartner Peer Insights** - product reviews and customer sentiment
- **Industry press** - TechCrunch, vertical trade publications
- **Company website and case studies** - product detail, customer names, positioning

---

## Common Pitfalls

- **Mistaking segment revenue for segment profit:** Revenue and operating income tell
  very different stories. Always look at margin by segment, not just top-line.
- **Missing the "so what" for our company:** A company profile without clear strategic
  implications is incomplete.
- **Treating private company estimates as facts:** Be explicit about what's estimated
  vs. disclosed, and on what basis.
- **Ignoring stock performance context:** A company down 20% post-earnings despite a
  "good" quarter often signals something structural worth understanding.
- **Net income distortions:** One-time tax benefits, FX gains, and restructuring charges
  can make net income misleading. Always check whether operating income tells a
  different story.
- **Fabricating concall triggers:** If you cannot find 4 concall transcripts, state
  how many you found and proceed. Never invent management guidance.
- **Conflating Walk the Talk with sentiment:** This section requires specific dated
  promises cross-referenced against specific outcomes. "Management seems confident"
  is not analysis.
- **Using press articles as primary financial data:** Always go to the SEC filing
  first. Press coverage of earnings often cherry-picks or mischaracterizes results.
  Use the Source Hierarchy.
- **Ignoring non-GAAP vs. GAAP divergence:** If the company presents non-GAAP figures
  prominently, always check what's being added back. Flag significant divergence.
- **Missing segment-level margin story:** Total company margins can hide a failing
  segment subsidized by a healthy one. Always break out segment margins when available.
