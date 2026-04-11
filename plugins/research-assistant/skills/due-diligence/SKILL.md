---
name: due-diligence
description: >
  Run due diligence on a company for investment, acquisition, or partnership decisions.
  Combines business model understanding, financial analysis, risk assessment, and deal
  thesis validation into a single go/no-go assessment. Use when someone asks "due diligence
  on [company]", "should we invest in [company]", "evaluate [company] as an acquisition
  target", "assess [company] for partnership", or any request for a holistic company
  evaluation tied to a specific deal or investment decision. Can be invoked directly or
  via the research orchestrator.
---

# Due Diligence Research Type

**Standalone execution:** If invoked directly (not via the research orchestrator),
follow the protocol in `../research/references/standalone-execution.md` to run the
full pipeline: company context -> internal recon -> plan -> launch agents -> monitor ->
synthesize.

Use this type when the goal is a holistic assessment of a company tied to a specific
decision - invest, acquire, partner, or pass. Due diligence integrates business
understanding, financial analysis, and risk assessment into a single verdict.

**Important distinctions:**
- **Due Diligence vs. Company Deep Dive:** Deep dive is about understanding a business.
  Due diligence is about making a decision about that business. Due diligence produces
  a verdict; deep dive produces comprehension.
- **Due Diligence vs. Company Financials:** Financials focuses on financial performance.
  Due diligence includes financials but also covers product risk, team risk, market
  risk, legal risk, and integration risk.
- **Due Diligence vs. Build/Buy/Partner:** B/B/P evaluates capability options. Due
  diligence evaluates a specific company as a target. If the question is "should we
  acquire a skills intelligence company?" use B/B/P. If the question is "should we
  acquire SkillsEngine specifically?" use due diligence.

---

## When to Use This Type

- "Run due diligence on [company]"
- "Should we invest in [company]?"
- "Evaluate [company] as an acquisition target"
- "Is [company] worth partnering with?"
- "What are the risks of [company]?"

---

## Step 0: Clarify the Deal Context (REQUIRED)

Before launching agents, establish:

1. **Decision type** - Is this an investment, acquisition, partnership, or vendor
   evaluation? The risk framework changes depending on the answer.
2. **Deal thesis** - Why is this company being considered? What's the hypothesis
   about why this would be a good decision? (If the user doesn't have a thesis,
   help them articulate one before proceeding.)
3. **Key concerns** - What's the user most worried about? What would make this a
   clear "no"? These become priority investigation items.

---

## Recommended Agent Workstreams

For due diligence, plan 3-4 agents:

**Agent 1: Business and Product Assessment**
Sections:
1. What the company does - plain-language explanation of the business model, product,
   and value proposition
2. Business model mechanics - how money flows, unit economics, revenue model
3. Product maturity - how developed is the product? Customer reviews, NPS signals,
   known limitations
4. Team and leadership - founders, key executives, hiring patterns, Glassdoor signals,
   key-person risk
5. Defensibility - what's the moat? Be honest. (Use the moat assessment from
   company-deep-dive: strong/moderate/weak/none)

**Agent 2: Market and Competitive Position**
Sections:
1. Market size and growth - TAM/SAM relevant to this company's actual addressable
   market (apply TAM skepticism from market-sizing)
2. Competitive position - who else is in the space? What's this company's share?
   Is the position improving or deteriorating?
3. Customer concentration - how dependent on a few customers? What's the churn rate?
4. Market risk - is this market growing, shrinking, or being disrupted? What could
   make this market unattractive in 3 years?

**Agent 3: Financial and Operational Assessment**
Sections:
1. Financial performance - revenue, growth rate, margins, burn rate, runway
   (use source hierarchy from company-financials: SEC filings > disclosed figures >
   estimates)
2. Capital structure - funding history, investors, debt, cap table implications
3. Operational health - headcount trends, hiring/firing patterns, office expansion/
   contraction, technology stack health
4. Financial red flags - apply the red flags checklist from company-financials

**Agent 4: Risk Assessment and Verdict**
(Runs AFTER Agents 1-3 complete - reads their output)
Sections:
1. Deal thesis validation - does the evidence support the original thesis?
   What's confirmed? What's challenged?
2. Risk inventory - categorized risks (see Risk Scoring Matrix below)
3. Deal breaker check - are any risks disqualifying?
4. Integration assessment (if acquisition) - what would integration look like?
   Complexity, timeline, key dependencies
5. Verdict and conditions - go, conditional go, or no-go. If conditional, state
   what must be verified before proceeding.

---

## Risk Scoring Matrix (REQUIRED)

Every due diligence must categorize and score risks. For each risk identified:

| Risk Category | Examples | Score |
|--------------|----------|-------|
| **Market risk** | Market shrinking, disruption, regulatory threat | High / Medium / Low |
| **Product risk** | Technical debt, scalability, feature gaps, platform dependency | High / Medium / Low |
| **Team risk** | Key-person dependency, leadership gaps, culture issues, retention risk | High / Medium / Low |
| **Financial risk** | Burn rate, revenue concentration, margin pressure, hidden liabilities | High / Medium / Low |
| **Competitive risk** | Competitor momentum, market share erosion, pricing pressure | High / Medium / Low |
| **Legal/IP risk** | Pending litigation, IP ownership questions, regulatory non-compliance | High / Medium / Low |
| **Integration risk** | (For acquisitions) Cultural fit, technology compatibility, retention | High / Medium / Low |

For each risk rated HIGH: explain the specific mechanism, the probability, and the
potential impact. High risks that could be disqualifying must be flagged explicitly.

---

## Deal Breaker Checklist (REQUIRED)

Check for these common deal breakers and flag any that are present:

1. **Customer concentration** - Does one customer represent >30% of revenue?
2. **Founder/key-person dependency** - Would the company collapse if a specific person left?
3. **Undisclosed liabilities** - Any signs of pending litigation, tax issues, or
   off-balance-sheet obligations?
4. **Market in structural decline** - Is the addressable market shrinking?
5. **Technology dead end** - Is the core technology approaching obsolescence?
6. **Regulatory exposure** - Is the company non-compliant with regulations that
   are likely to be enforced?
7. **Cash runway** - Less than 6 months of runway with no clear path to profitability
   or next funding?
8. **Negative reference signals** - Customer churn accelerating, Glassdoor reviews
   deteriorating, key hires departing?

Not every flag is a deal breaker in every context - but each must be explicitly
acknowledged and assessed.

---

## Key Data Sources

- **SEC filings** (public companies) - 10-K, 10-Q, S-1 for financial and risk data
- **Crunchbase / PitchBook** - funding history, investors, valuation
- **LinkedIn** - headcount trends, hiring patterns, leadership tenure, departures
- **Glassdoor / Blind** - employee sentiment, culture signals, leadership reviews
- **G2, Gartner Peer Insights** - customer reviews, product perception
- **Court records / PACER** - litigation history (if concerns exist)
- **Patent databases** - IP portfolio strength
- **Press and industry coverage** - recent news, partnerships, customer wins/losses
- **Earnings call transcripts** (public companies) - management commentary and guidance

---

## Output Structure for Synthesis

1. **Verdict** - first sentence. Go, conditional go, or no-go. With one-line rationale.
2. **Deal thesis recap** - what was the hypothesis? (2-3 sentences)
3. **Thesis validation** - what does the evidence say? Is the thesis supported,
   partially supported, or undermined?
4. **Business summary** - what the company does, how it makes money, what's defensible.
   One paragraph.
5. **Financial snapshot** - key numbers: revenue, growth, margins, burn, runway.
   Table format.
6. **Risk assessment** - the Risk Scoring Matrix with explanations for all HIGH risks.
7. **Deal breaker flags** - any items from the checklist that are flagged, with
   explanation.
8. **Key questions for next phase** - what must be verified before finalizing the
   decision? (3-5 specific items, e.g., "verify customer retention data directly
   with references," "confirm IP ownership with legal review")

---

## Common Pitfalls

- **Falling in love with the thesis.** Due diligence exists to stress-test, not confirm.
  Actively look for disconfirming evidence.
- **Treating financial estimates as facts.** For private companies, label every
  non-disclosed figure as [ESTIMATE] with methodology.
- **Skipping the deal-breaker checklist.** Run it every time, even if the company
  looks strong. The checklist catches things optimism misses.
- **Integration hand-waving.** "Integration should be straightforward" is not analysis.
  Specify what needs to integrate, the timeline, and what could go wrong.
- **No verdict.** Due diligence without a clear go/no-go/conditional recommendation
  is incomplete. Take a position.
