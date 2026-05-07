---
name: research-competitive-analysis
description: >
  Run a competitive analysis - landscape scans, competitor profiles, positioning matrix,
  and strategic implications. Use when someone asks about competitors, competitive
  landscape, "who are we up against", "how does X compare", or "do a competitive
  analysis of Y". Can be invoked directly or via the research orchestrator.
---

# Competitive Analysis Research Type

**Standalone execution:** If invoked directly (not via the research orchestrator),
follow the protocol in `../research/references/standalone-execution.md` to run the
full pipeline: company context → internal recon → plan → launch agents → monitor →
synthesize.

Use this type when the research question is about understanding the competitive
landscape - who the players are, how they compete, where the company is differentiated,
and where it's exposed.

**Important distinction:** Competitive Analysis is about rivals in your domain.
If the question is about finding companies that solved a structurally similar problem
in a different domain, that's Analog Mapping - a completely different type with
different output goals (warm introductions vs. competitive positioning).

---

## Step 0: Validate the Competitive Set (REQUIRED)

Before any agent launches, the competitive set must be validated. The single most
common failure mode in competitive analysis is profiling the wrong companies —
researching adjacent platforms or generic category players instead of the companies
that actually show up in deals.

### How to validate:

1. **Check company context** — Read the active company context file from
   `../research/references/contexts/` for any win/loss data, named competitors, or
   sales battle cards. If the context names specific competitors, those are the
   starting set.

2. **Ask the user if unclear** — "Which competitors actually show up in your deals?
   Who do buyers evaluate alongside you?" The user's answer overrides any research.

3. **Apply the buyer test** — For each company you're considering profiling: "Would a
   buyer evaluating [our company] also request a demo from [this company]?" If no,
   it's not a direct competitor. It might be indirect or adjacent, but it shouldn't
   get a full profile.

4. **Distinguish the competitive set from the market landscape** — Companies in the
   same broad industry are not necessarily competitors. A CRM platform and a marketing
   automation tool both serve marketers but don't compete head-to-head. Category
   confusion produces useless analysis. Be precise about what category the company
   actually competes in.

### Output:
Before presenting the research plan, state the validated competitive set:
- **Direct competitors (full profiles):** [2-4 companies]
- **Indirect competitors (short profiles):** [1-3 companies]
- **Adjacent players (brief mention):** [1-3 companies]

Wait for user confirmation of this list before proceeding.

---

## When to Use This Type

- "Who are our main competitors in [market]?"
- "Do a competitive landscape on [market/product area]"
- "How does [competitor] compare to us?"
- "Where are we differentiated vs. [competitor]?"
- "What would a buyer choose instead of us?"
- "What's happening in the [category] space?"

---

## Recommended Agent Workstreams

For most competitive analyses, plan 2-3 agents:

**Agent 1: Landscape Overview**
Sections:
1. Market structure - how many serious players, how are they segmented (by buyer,
   product type, deal size, geography)?
2. Competitive category map - which companies compete in which parts of the space?
3. Recent market activity - funding rounds, M&A, new product launches, notable
   wins/losses in the last 12-18 months
4. Buyer perspective - how do buyers think about this category? What problems are
   they trying to solve? What's their evaluation process?

**Agent 2: Competitor Deep Dives**
For each major competitor (typically 3-5), cover:
1. Product and capabilities - what do they actually do? What's their core value prop?
2. Target customer - which buyers do they go after? What's their ICP?
3. Pricing and deal structure - how do they charge? What's a typical ACV?
4. Strengths - where are they genuinely better or more established?
5. Weaknesses - where do they fall short? What do customers complain about?
6. Business momentum (REQUIRED - see Momentum Framework below)

**Agent 3: Positioning and Differentiation Analysis**
Sections:
1. Feature/capability comparison matrix - the company vs. top 3-4 competitors on
   key dimensions
2. Where the company wins - specific situations, buyer types, or deal contexts where
   it has a genuine advantage
3. Where the company is exposed - competitive threats, feature gaps, pricing risks
4. How competitors position against the company - what do they say in competitive
   sales situations?
5. White space - areas of uncontested opportunity no one is fully addressing

---

## Key Data Sources

- **Company websites and product pages** - start here for positioning language
- **G2, Gartner Peer Insights, Capterra** - user reviews; reveals real strengths
  and weaknesses that marketing hides
- **Crunchbase, PitchBook** - funding history, investor backing, growth signals
- **LinkedIn** - headcount trends, hiring patterns, leadership changes
- **SEC filings (10-K, S-1)** - for public companies; revenue, segment data, risk factors
- **Press releases and case studies** - customer wins, pricing signals, partnerships
- **Job postings** - open roles reveal what a company is actively building
- **Industry analyst reports** - Gartner Magic Quadrants, Forrester Waves for the
  relevant category (may be paywalled)

---

## Competitor Categorization (REQUIRED)

Every competitive analysis must explicitly categorize each company into one of three
tiers. Do not treat all competitors equally — spend the most time on companies that
actually show up in the company's deals.

### Three tiers:

**Direct Competitors:**
Companies that a buyer would evaluate as an alternative to the company. They serve
the same buyer, solve the same problem, and compete head-to-head in deals. These
get full profiles (see Momentum Framework below).

**Indirect Competitors:**
Companies that solve the same problem differently — a different delivery model,
different buyer entry point, or different product category that achieves the same
outcome. They may not show up in RFPs but they reduce the urgency to buy. These get
shorter profiles (one paragraph) focused on: what they substitute for and why a
buyer might choose the indirect path.

**Adjacent Players:**
Companies that don't compete today but could. They're in the same ecosystem, serve
the same buyer for different needs, and have the distribution or capability to expand
into the space. These get a brief mention: who they are, what would trigger them to
compete, and how likely that is.

State the categorization explicitly at the top of each competitor entry.

---

## Momentum Framework (REQUIRED)

Every competitor profile — whether written by the research agent or in the synthesis —
must state the competitor's **trajectory**, not just its current state. "They offer X
and serve Y" is a snapshot. "They grew revenue 40% YoY and are hiring aggressively in
enterprise sales" is momentum.

### Required momentum evidence (at least 2 of the following):

- **Funding trajectory:** Recent round size, investor quality, time since last raise.
  A Series D from Tier 1 VCs signals different momentum than a flat extension round.
- **Hiring signals:** Net headcount change over 12 months (LinkedIn), which functions
  are growing (engineering = building; sales = scaling; customer success = retention
  problems or growth).
- **Revenue or ARR trajectory:** For public companies, revenue growth rate from filings.
  For private, any disclosed revenue milestones, customer count growth, or press
  references to revenue scale.
- **Customer momentum:** Named customer wins, logo churn, NPS or review sentiment
  trend on G2/Gartner Peer Insights. Net new reviews trending up or down.
- **Market share trend:** Analyst positioning changes (Gartner MQ movement, Forrester
  Wave placement shifts), win rate changes in competitive deals if known.

### Trajectory classification:

Every competitor must be tagged with one of:
- **Accelerating** — multiple momentum signals pointing up; gaining share
- **Steady** — stable position, neither gaining nor losing meaningfully
- **Decelerating** — warning signs: flat hiring, leadership turnover, funding drought,
  negative review trends
- **Pivoting** — actively shifting strategy, product, or market focus; trajectory
  uncertain

State the classification and the 2-3 data points that support it. "Accelerating based
on [evidence]" — not just the label.

---

## Positioning Matrix (REQUIRED)

Every competitive analysis synthesis must include a positioning matrix that makes
differentiation visual and concrete.

### Format:
Use a 2x2 matrix OR a comparison table — whichever communicates the competitive
dynamics more clearly for THIS specific market.

### Axis selection:
The two axes must be chosen based on what actually differentiates competitors in
this market. Do NOT default to generic axes. Common axis pairs:

- Enterprise vs. SMB + Platform vs. Point Solution
- Price/Cost vs. Depth/Capability
- Self-Serve vs. High-Touch + Horizontal vs. Vertical
- Technology-Led vs. Services-Led + Broad vs. Specialized
- Buyer Entry Point: HR vs. Operations vs. Finance + Delivery Model

**Name the axes explicitly** and explain in 1-2 sentences why these two dimensions
are the ones that matter most for this market. If the competitive dynamics don't
map cleanly to two axes, use a comparison table with 4-6 attributes instead.

### Placement evidence:
Each company's position on the matrix must be justified with a brief note — not
just plotted. "Company X is top-right because [evidence]."

---

## Output Structure for Synthesis

The synthesis follows the Competitive Analysis format specified in the synthesis skill.
Key sections:

1. **Competitive thesis** (2-3 sentences): What's the overall dynamic in this market?
   Who's winning and why? Take a position.
2. **Market structure**: How many serious players? How are they segmented? Explicitly
   categorize as Direct, Indirect, or Adjacent (see Competitor Categorization above).
3. **Competitor profiles** (prose, not bullets): One paragraph per major competitor
   covering product, customers, **momentum with trajectory classification** (see
   Momentum Framework above), and how they compare. Every profile MUST state trajectory
   with evidence — not just current state.
4. **Positioning matrix**: 2x2 or comparison table with **explicitly named axes** (see
   Positioning Matrix section above). Justify each company's placement.
5. **The company's competitive position**: Where it wins, where it's exposed, what's
   defensible, what's at risk. Prose, not bullets.
6. **Strategic implications**: Specific actions. "Monitor X" is not acceptable. "Invest
   in Y because competitor Z is closing the gap on feature W" is.

---

## Common Pitfalls

- **Surface-level feature comparison:** Don't just list features - explain which ones
  *matter* to buyers and why.
- **Ignoring perception vs. reality:** A competitor might have a weaker product but
  stronger brand or distribution. Market perception matters as much as capability.
- **Treating all competitors equally:** Spend more time on the 2-3 that actually show
  up in the company's deals. Don't give equal coverage to fringe players. Use the
  Direct/Indirect/Adjacent categorization to allocate depth appropriately.
- **No "so what":** A competitive analysis without clear strategic implications is
  incomplete. "Monitor" is not a strategy.
- **Snapshot without momentum:** Describing what a competitor does today without stating
  whether they're accelerating, steady, decelerating, or pivoting. Every profile needs
  trajectory with evidence.
- **Generic positioning axes:** Defaulting to "price vs. quality" or similar generic
  axes that don't illuminate the actual competitive dynamics in THIS market. Choose
  axes that reveal differentiation.
- **Missing the indirect threat:** The biggest competitive risk is often not the company
  in the same category but the one solving the problem a different way (internal builds,
  adjacent products, "good enough" substitutes).
