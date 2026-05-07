---
name: market-sizing
description: >
  Size a market - TAM/SAM/SOM estimates, territory analysis, opportunity sizing. Use
  when someone asks "how big is the market for", "what's the TAM", "size the opportunity",
  "how many potential buyers", or any request to quantify an addressable market. Can be
  invoked directly or via the research orchestrator.
---

# Market Sizing Research Type

**Standalone execution:** If invoked directly (not via the research orchestrator),
follow the protocol in `../research/references/standalone-execution.md` to run the
full pipeline: company context → internal recon → plan → launch agents → monitor →
synthesize.

Use this type when the research question is about sizing an opportunity -
TAM/SAM/SOM, territory analysis, or quantifying the addressable market for a
product or initiative.

---

## When to Use This Type

- "How big is the market for [product] in [geography/segment]?"
- "What's the TAM for [category]?"
- "Help us size the opportunity in [industry/vertical]"
- "Which territories or segments should we prioritize?"
- "What's the total number of [customers/companies] we could sell to?"

---

## Recommended Agent Workstreams

For most market sizing projects, plan 2-3 agents:

**Agent 1: Top-Down Market Sizing**
Sections:
1. Total addressable market (TAM) - industry-level estimates from analyst firms,
   government data, trade associations
2. Serviceable addressable market (SAM) - filtered for the company's qualifying
   criteria (geography, segment, ICP fit)
3. Market growth rate and tailwinds - 3-5 year projections; what's driving growth?
4. Key sizing assumptions and their sources

**Agent 2: Bottom-Up Market Sizing**
Sections:
1. Universe of qualifying buyers - number of companies or individuals meeting the
   company's ideal customer profile (ICP)
2. Buyer spend benchmarks - average spend per customer, participation or adoption rates
3. Per-customer revenue potential - ACV benchmarks, deal size ranges
4. Implied market size from bottom-up build

**Agent 3: Territory or Segment Deep Dive** (if sizing a specific geography or segment)
Sections:
1. Segment or territory overview - key buyers, demographics, industry mix
2. Competitive presence - which competitors are already there and how entrenched?
3. Regulatory or structural factors - industry-specific requirements, compliance needs
4. Sizing this segment specifically - how much of the TAM/SAM is here?

---

## Penetration Rate Discipline (REQUIRED)

Market sizing is useless without penetration assumptions, and penetration assumptions
are where most market sizing goes wrong. Every sizing output must explicitly address
penetration at three levels:

### Category penetration:
What percentage of the theoretical buyer universe actually buys this category of
product at all? Many markets have large theoretical TAMs but low category penetration
because most buyers haven't adopted the category yet. State the current penetration
rate with source. If unknown, estimate it and label it [ESTIMATE].

### Vendor penetration within adopters:
Of buyers who do buy this category, what share could realistically choose this company
given its ICP, geography, go-to-market model, and competitive position? This is where
TAM becomes SAM. Be ruthless — most companies can realistically address 10-30% of
adopters, not 100%.

### Wallet share:
Of the money a qualifying buyer spends in this category, what share could this company
capture? Especially important in markets where buyers use multiple vendors or where
the company's product addresses only part of the buyer's spend.

**Every sizing output must show:** TAM × Category Penetration × Vendor Penetration ×
Wallet Share = Realistic Addressable Opportunity. Skipping any layer produces inflated
numbers.

---

## TAM Skepticism Framework (REQUIRED)

Most published TAM figures are wrong — they're designed to make markets look large for
fundraising or analyst reports, not to inform investment decisions. Apply these filters
to every TAM figure encountered:

### Source bias check:
- **Vendor-published TAMs** (in pitch decks, press releases, or marketing): Assume
  inflated by 2-5x. These are designed to excite investors, not to be accurate.
  Cross-check with independent bottom-up.
- **Analyst firm TAMs** (Gartner, IDC, Forrester): Often include adjacent markets or
  use broad definitions. Check what's included in their definition vs. what the
  company actually sells. A "$50B market" may include $40B of things unrelated to the
  company's product.
- **Trade association TAMs**: Usually measure the entire industry, not the software/
  services layer the company sells into. A "$200B industry" where the addressable
  software spend is $2B is a $2B market.
- **Bottom-up TAMs from public company revenue**: Most reliable, but only covers the
  current market — doesn't account for market expansion or contraction.

### Red flags that a TAM is inflated:
- The number is round ($10B, $50B, $100B) — real bottom-up numbers are messy
- The growth rate is >25% CAGR for a market that's been around for 5+ years
- The TAM is larger than the total spend of the buyer category it claims to address
- Multiple analyst firms give wildly different numbers (suggests the market definition
  is unstable)
- The TAM includes "potential" or "if fully penetrated" language

### What to do when TAMs conflict:
State all figures with sources. Run a quick bottom-up sanity check: [number of buyers]
× [realistic average spend] = implied TAM. If the bottom-up is 3x+ smaller than the
top-down, the top-down is probably inflated. Explain the gap.

---

## Private Market Sizing Guidance

When sizing markets where no analyst has published a TAM (common for emerging categories
or niche verticals), agents must build the estimate from scratch:

1. **Define the buyer universe** - Use government data (BLS, Census), industry
   associations, or LinkedIn to count qualifying organizations. State the filter
   criteria explicitly.
2. **Estimate adoption rate** - Use proxy markets. If 15% of mid-market companies buy
   HR analytics software, and this product is an adjacent category, 15% is a reasonable
   starting ceiling — not a floor.
3. **Estimate average deal size** - Use comparable products (similar buyer, similar
   complexity, similar value prop) as ACV proxies. State the comp and why it's valid.
4. **Triangulate** - Run the math two ways (different buyer definitions, different ACV
   assumptions) and show the range. A range is more honest and more useful than a
   single point estimate.

Never present a single point estimate without a range. The range communicates the
uncertainty — which is the most important thing about any market sizing exercise.

---

## Key Data Sources

Point agents to these sources first:

- **Government statistical agencies** - workforce data, industry employment, census data
  (BLS, Census Bureau in the US; Eurostat in Europe; etc.)
- **Industry associations** - often publish market size reports for their vertical
- **Public company filings (10-K, 10-Q)** - competitor revenue gives bottom-up signals
- **Analyst firms** - Gartner, Forrester, IDC, IBISWorld for published market size
  estimates (may be paywalled; note and move on)
- **LinkedIn / job postings** - proxy for employer universe and hiring demand
- **Crunchbase / PitchBook** - funding flows signal market activity and growth

---

## Output Structure for Synthesis

The synthesis follows the Market Sizing format specified in the synthesis skill.
Key sections:

1. **Headline number** - one sentence, first line of the document: "$[X] [TAM/SAM]
   based on [methodology]." Do NOT bury this. The first sentence states the number.
2. **Top-down estimate** - analyst/industry data approach with sources AND fiscal year.
   Apply TAM Skepticism Framework — flag any source bias.
3. **Bottom-up estimate** - buyer universe × deal economics approach. Show the math
   explicitly: [# buyers] × [penetration rate] × [ACV] = [implied market].
4. **Reconciliation** - if the two approaches diverge (they usually do), explain why
   and explicitly state which number to use for decision-making and why.
5. **Penetration waterfall** - TAM × Category Penetration × Vendor Penetration ×
   Wallet Share = Realistic Addressable Opportunity (see Penetration Rate Discipline).
6. **Segment or territory breakdown** - where is the opportunity concentrated? Table
   format for 3+ segments.
7. **Key assumptions** - the 3-5 assumptions that, if wrong, change the number most.
   For each: what the assumption is, what number it affects, and what range of outcomes
   results from changing it.
8. **Implications** - what the sizing means for the specific decision at hand. Not
   "this is a large market" but "this supports/doesn't support [investment/expansion/
   hiring decision] because [specific reasoning]."

---

## Common Pitfalls

- **Confusing TAM with SAM:** TAM is the entire industry; SAM is what the company
  could realistically sell to. Be precise. Apply the penetration waterfall.
- **Using inflated analyst figures:** Many analyst TAMs include adjacent markets or
  assume 100% penetration. Cross-check with bottom-up. Apply the TAM Skepticism
  Framework to every published figure.
- **Ignoring competition:** Market size doesn't equal the company's opportunity -
  always note how much is already captured by incumbents.
- **No denominator:** "X buyers" is not useful without the total universe. Always
  state penetration rates explicitly.
- **Single point estimate without a range:** Every market size should be presented as
  a range with the key variable that moves it. A confident "$4.2B" is less useful than
  "$2.8B-$5.1B depending on category adoption rate."
- **Fundraising math presented as market size:** Companies in pitch decks routinely
  count every possible dollar in every possible buyer as "TAM." That's fundraising
  theater, not market sizing. The bottom-up sanity check catches this.
- **Growth rate extrapolation from a small base:** A market that grew 80% last year
  from $50M to $90M is not a "$1B market in 3 years." Small-base growth rates don't
  compound at that rate. Use S-curve logic for emerging markets.
- **Confusing industry size with software addressable market:** The healthcare industry
  is $4T. The addressable market for a healthcare SaaS product is not $4T. Always
  specify which layer of the market the company actually sells into.
