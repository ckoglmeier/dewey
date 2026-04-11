---
name: eval
description: >
  Evaluate research output quality against structured rubrics. Two modes: (1) Run a
  research type end-to-end and score the output, or (2) Score an existing research
  document. Use when someone asks "eval this research type", "test [type]", "score this
  output", "benchmark [type]", "quality check this research", or any request to measure
  research quality. Can be invoked directly.
---

# Research Eval Harness

Evaluates research output quality against type-specific rubrics. Can run research
from scratch and score the result, or score an existing document.

---

## Mode 1: Run and Score (Full Eval)

Use when the user wants to test a research type end-to-end.

### Step 1: Determine Parameters

1. **Research type** — which type? (competitive-analysis, industry-trend, market-sizing,
   analog-mapping, build-buy-partner, company-deep-dive, company-financials,
   technology-landscape, regulatory-landscape, due-diligence, person-profile,
   ecosystem-map)
2. **Research prompt** — what question should the research answer? If the user doesn't
   provide one, use the default eval prompt for the type (see table at bottom).

### Step 2: Run the Research

Launch the research using the type skill's standalone execution protocol:
- Read the type skill, synthesis skill, write protocol, and company context
- Launch 2-3 parallel research agents per the type skill's workstreams
- Each agent must use WebSearch and WebFetch for real data
- Run synthesis after agents complete
- Output to: `research/eval-[type]-[date]/`

### Step 3: Score the Output

Read the synthesis file and score against the rubrics in Step 3 below.

---

## Mode 2: Score Existing Output

Use when the user has an existing research document they want evaluated.

### Step 1: Identify the Document

Read the file the user provides or points to.

### Step 2: Identify the Research Type

Determine which type this is based on content (competitive profiles = competitive
analysis, TAM figures = market sizing, etc.). If unclear, ask.

### Step 3: Score Against Rubrics

Proceed to scoring below.

---

## Scoring Rubrics

Score each criterion 1-5. Present as a table with scores, then write 3-5 sentences
explaining the key strengths and gaps.

### Universal Rubric (applies to all types)

| Criterion | 1 (Poor) | 3 (Adequate) | 5 (Excellent) |
|-----------|----------|--------------|---------------|
| **Thesis clarity** | No clear position taken | Position stated but hedged | Sharp, opinionated thesis in first 2-3 sentences |
| **Source quality** | No inline sources | Some sources, mix of quality | Every claim sourced with inline URLs, credible sources, no fabricated URLs |
| **Prose quality** | Excessive bullets, jargon, padding | Mostly prose, some drift | Clean prose throughout, no corporate jargon, no bullet-point analysis |
| **Actionability** | Generic observations ("worth watching") | Some specific actions | Every implication tied to a specific decision or action |
| **Instructions leak** | Agent boilerplate visible | Minor metadata (status/date) | Clean: title on line 1, no process artifacts |
| **Length discipline** | Significant padding, redundant sections | Reasonable length | Focused, every sentence adds understanding; within type target range |

### Type-Specific Rubric: Competitive Analysis

| Criterion | 1 | 3 | 5 |
|-----------|---|---|---|
| **Competitor identification** | Wrong competitive set entirely | Right companies but no categorization | Correct set with explicit Direct/Indirect/Adjacent labels |
| **Momentum framework** | No trajectory assessment | Some trajectory mentions | Every competitor tagged Accelerating/Steady/Decelerating/Pivoting + 2+ evidence points |
| **Positioning matrix** | No matrix | Generic or unlabeled axes | Named axes with rationale, placement justified per company |
| **Competitive set validation** | No evidence of buyer test | Some justification | Clear statement of who shows up in deals; categorization confirmed |

### Type-Specific Rubric: Industry Trend

| Criterion | 1 | 3 | 5 |
|-----------|---|---|---|
| **Signal vs. Noise** | All trends treated equally | Some skepticism shown | Every trend classified SIGNAL/NOISE/TOO EARLY with behavioral evidence |
| **Temporal framing** | Vague timing ("emerging") | Some dates | Every trend tagged Now/Near-term/Medium-term/Structural |
| **Source credibility** | All sources treated equally | Some ranking | Behavioral data > earnings > research > surveys > vendor content; gaps surfaced |
| **Overhype identification** | No noise called out | Passing mention | Dedicated section naming 1-3 overhyped trends with specific debunking |

### Type-Specific Rubric: Market Sizing

| Criterion | 1 | 3 | 5 |
|-----------|---|---|---|
| **Headline number** | Buried or absent | Present but not first sentence | First sentence states the number + methodology |
| **Penetration waterfall** | TAM only, no penetration | Some penetration discussion | Full waterfall: TAM x category x vendor x wallet share |
| **TAM skepticism** | Published figures taken at face value | Some cross-checking | Source bias flagged, bottom-up sanity check run, range provided |
| **Top-down / bottom-up reconciliation** | Only one approach | Both present but no reconciliation | Both approaches with explicit gap explanation and recommendation |

### Type-Specific Rubric: Analog Mapping

| Criterion | 1 | 3 | 5 |
|-----------|---|---|---|
| **DNA extraction** | No structural comparison | Some model comparison | 7-dimension DNA with archetype-specific framing |
| **Required sections** | Missing 3+ sections | Missing 1-2 sections | All 7 required sections present and substantive |
| **Investor mapping** | No investor data | Some investors named | Cross-cutting investor network with overlap counts and intro paths |
| **Economics coverage** | No financial mechanics | Revenue model mentioned | Take rates, unit economics, and scale economics for each analog |

### Type-Specific Rubric: Build/Buy/Partner

| Criterion | 1 | 3 | 5 |
|-----------|---|---|---|
| **Recommendation up front** | Buried or absent | Present but hedged | First sentence states clear recommendation |
| **Do-nothing evaluated** | Not mentioned | Mentioned but dismissed | Seriously evaluated with specific cost-of-delay analysis |
| **Named targets** | Generic "companies exist" | Some names | 2-3 specific targets with profiles, deal size estimates, and fit assessment |
| **Decision rigor** | No framework applied | Some tradeoff discussion | Switching costs, time-to-value, and dependency stress test all addressed |

### Type-Specific Rubric: Company Deep Dive

| Criterion | 1 | 3 | 5 |
|-----------|---|---|---|
| **Business model anatomy** | Surface description only | Most dimensions covered | All 7 dimensions of Business Model Anatomy clearly addressed |
| **Concall coverage** | No concalls found | 1-2 concalls | 4 concalls with specific dated citations |
| **Walk the Talk** | Sentiment only ("management seems confident") | Some promise tracking | Specific dated promises cross-referenced against outcomes with verdict |
| **Moat assessment** | Forced moat narrative | Moat discussed but not graded | Explicit strong/moderate/weak/none assessment with reasoning |
| **No financials rule** | Revenue/margins present | Minor financial references | Zero financial figures anywhere in the document |

### Type-Specific Rubric: Company Financials

| Criterion | 1 | 3 | 5 |
|-----------|---|---|---|
| **Source hierarchy** | Press articles as primary source | Some SEC data | SEC filings primary, earnings transcripts for color, clear source labeling |
| **Structured format** | Free-form narrative | Partial structure | Full earnings format (Revenue, Profitability, Metrics, Valuation, Walk the Talk) |
| **Walk the Talk** | Missing entirely | Sentiment only | Dated promises vs. outcomes across 4 concalls with verdict |
| **Red flags check** | No financial scrutiny | Some questioning | Non-GAAP divergence, segment margins, cash flow checked; flags raised if present |

### Type-Specific Rubric: Technology Landscape

| Criterion | 1 | 3 | 5 |
|-----------|---|---|---|
| **Vendor coverage** | Fewer than 3 vendors profiled | 3-5 vendors with basic descriptions | 5-8 vendors with capabilities, target buyer, pricing, and limitations |
| **Maturity framework** | No maturity assessment | Some maturity labels | Every vendor classified Emerging/Growing/Mature/Declining with evidence |
| **Feature comparison** | No comparison | Prose comparison | Structured feature matrix with clear ratings across key capabilities |
| **Adoption signals** | Vendor marketing claims only | Some adoption evidence | Named customer deployments, job postings, community activity checked |

### Type-Specific Rubric: Regulatory Landscape

| Criterion | 1 | 3 | 5 |
|-----------|---|---|---|
| **Certainty tagging** | Regulations listed without status | Some status notes | Every regulation tagged ENACTED/FINAL RULE/PROPOSED/EXPECTED/SPECULATIVE |
| **Compliance burden** | Requirements listed but not assessed | Some burden discussion | Full burden matrix: cost, time, expertise, maintenance, business impact |
| **Jurisdiction coverage** | Single jurisdiction or vague "US" | Major jurisdictions noted | Jurisdiction matrix with clear comparison across relevant geographies |
| **Enforcement posture** | No enforcement context | Some enforcement noted | Recent cases, fines, and enforcement trends with specific examples |

### Type-Specific Rubric: Due Diligence

| Criterion | 1 | 3 | 5 |
|-----------|---|---|---|
| **Verdict** | No clear recommendation | Recommendation present but buried | Go/conditional-go/no-go in first sentence with rationale |
| **Risk scoring** | Risks mentioned loosely | Some risk categorization | Full Risk Scoring Matrix (7 categories) with HIGH risks explained |
| **Deal breaker checklist** | No systematic check | Some flags checked | All 8 deal breaker items explicitly assessed |
| **Thesis validation** | Thesis restated, not tested | Partial evidence review | Original thesis explicitly confirmed, challenged, or undermined with evidence |

### Type-Specific Rubric: Person Profile

| Criterion | 1 | 3 | 5 |
|-----------|---|---|---|
| **First-person sources** | No quotes or own words | Some LinkedIn mentions | Conference talks, articles, podcast appearances, LinkedIn posts as primary sources |
| **Career narrative** | Chronological resume format | Some narrative framing | Story of career trajectory that explains who they are and what drives them |
| **Meeting prep brief** | No actionable prep | Some conversation tips | Full brief: 3 things to know, conversation starters, watch-fors, and don'ts |
| **Recency** | Sources older than 12 months | Mix of old and recent | Last 6 months of activity covered, source dates noted throughout |

### Type-Specific Rubric: Ecosystem Map

| Criterion | 1 | 3 | 5 |
|-----------|---|---|---|
| **Relationship mapping** | Players listed without connections | Some partnerships noted | Relationships documented with type, depth, stability, and exclusivity |
| **Power analysis** | All players treated equally | Some leverage discussion | 5-8 players classified Dominant/Influential/Participant/Dependent with evidence |
| **Value flow** | No money/data flow described | Some revenue discussion | Clear picture of who pays whom, where margin concentrates, where bottlenecks exist |
| **Strategic implications** | Generic "explore partnerships" | Some specific targets | Specific partnership targets ranked by value and feasibility, risks named |

---

## Output: Eval Report

Write the eval report to `research/eval-[type]-[date]/eval-report.md` with:

1. **Score table** — all applicable criteria (universal + type-specific) with scores
2. **Total score** — sum and percentage (e.g., 42/50 = 84%)
3. **Strengths** (2-3 sentences) — what the output does well
4. **Gaps** (2-3 sentences) — what's missing or weak, with specific examples
5. **Skill improvement recommendations** — if gaps trace to skill instructions rather
   than agent execution, suggest specific edits to the type or synthesis skill

Present results to the user with a concise summary.

---

## Scoring Thresholds

| Score Range | Assessment |
|------------|-----------|
| 90-100% | Excellent — production-ready, frameworks fully applied |
| 75-89% | Good — minor gaps, usable as-is with light editing |
| 60-74% | Adequate — frameworks partially applied, needs revision |
| Below 60% | Needs work — significant structural or content gaps |

---

## Default Eval Prompts by Type

Use these if the user doesn't provide a custom prompt.

| Type | Default Eval Prompt |
|------|-------------------|
| competitive-analysis | "Do a competitive analysis of [your company]'s market — who are the key competitors and how are they positioned?" |
| industry-trend | "What's happening in [your company's primary market]? How are buyers thinking about this category right now?" |
| market-sizing | "How big is the addressable market for [your company's product category]? Include TAM, SAM, and realistic addressable opportunity." |
| analog-mapping | "Show me B2B marketplace analogs to [your company]'s model. What are their economics, take rates, and operational patterns?" |
| build-buy-partner | "Should [your company] build, buy, or partner for [capability gap]?" |
| company-deep-dive | "Deep dive on [target company] — how does the business actually work?" |
| company-financials | "Pull the latest financials on [target public company] and assess their performance." |
| technology-landscape | "Map the [technology category] landscape — what tools exist, how do they compare, and which should we evaluate?" |
| regulatory-landscape | "What's the regulatory landscape for [market/product/activity]? What do we need to comply with?" |
| due-diligence | "Run due diligence on [target company] as a potential [investment/acquisition/partnership]." |
| person-profile | "Prep me for a meeting with [person name, title, company]. What should I know?" |
| ecosystem-map | "Map the ecosystem around [market/platform] — who are the players, how do they relate, and where does power sit?" |
