# Setting Up the Strategy-Feedback Plugin

## First-Time Setup

After installing the plugin, you need to configure at least one company context. The plugin works generically without company context, but the output is dramatically better with it.

### Option 1: Guided Setup (Recommended)

Say: **"Set up a new company for [your company name]"**

The competitive-intel skill will walk you through:

1. **Company Profile** — Who you are, what you sell, who buys it
2. **Competitive Landscape** — Your top competitors, win/loss patterns, displacement strategies
3. **Strategic Decisions** — Current strategic pillars, recent major decisions, active debates
4. **Market Context** — TAM/SAM, market trends, buyer behavior shifts, regulatory landscape
5. **Strategy Council Personas** — 8-12 personas for strategic decision-making debates
6. **Buyer Personas** — Your buyer types and internal commercial voices for GTM feedback

The skill will research your company, competitors, and market using available tools (web search, Glean, Slack) and draft each file for your review.

### Option 2: Manual Setup

1. Navigate to `skills/competitive-intel/companies/`
2. Copy the `_template/` directory and rename it to your company name in kebab-case (e.g., `acme-corp`)
3. Fill in each file following the templates
4. The plugin will automatically detect the new company directory

## Adding a Second Company

Say: **"Set up a new company for [company name]"** — the plugin creates a new directory alongside your existing company. When multiple companies exist, the plugin asks which context to use (or auto-matches from your question).

## File Reference

Each company directory contains six files:

| File | What It Contains | Who Should Update It |
|------|-----------------|---------------------|
| `company-profile.md` | Company overview, products, buyers, brand | Strategy / Product team |
| `competitive-landscape.md` | Competitors, positioning, win/loss | Strategy / Competitive Intel team |
| `strategic-decisions.md` | Strategic pillars, recent decisions | Leadership / Strategy team |
| `market-context.md` | TAM, trends, buyer behavior, regulatory | Strategy / Market Research |
| `strategy-council-personas.md` | 8-12 personas for strategy debates | Plugin owner |
| `buyer-personas.md` | Buyer types and internal commercial voices | Marketing / Sales / Plugin owner |

## Persona Design Tips

**Strategy Council personas** should represent the perspectives that matter when making internal strategic decisions. Think: who would you want in the room when deciding whether to build a new product, change pricing, or enter a new market? Good archetypes: investor (early and late stage), CRO, CFO, CTO, your primary buyer, your end user, domain experts relevant to your industry.

**Buyer Persona Council personas** should represent how your buyers actually think and decide. Include industry/segment variations of your primary buyer, the budget owner, the champion, the operational leader, the financial skeptic. Add 2-3 internal voices (CRO, CMO, user advocate) who bridge between what the company says and what buyers hear.

**The best personas have:**
- A clear, narrow analytical lens (what they evaluate)
- Specific red flags (what makes them skeptical)
- Signature questions (what they always ask)
- Defined conflicts with other personas (where they disagree)

## Verifying Setup

After setup, test with:
- "What's our competitive landscape?" — should return your company's competitive data
- "Council: should we build [something]?" — should activate your company-specific personas
- "Persona council: review this messaging" — should activate your buyer personas
