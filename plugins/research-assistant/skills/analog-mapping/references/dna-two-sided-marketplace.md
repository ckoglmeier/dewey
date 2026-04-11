# DNA Extraction Template: Two-Sided Marketplace / Platform

Use when the seed company connects buyers and sellers (or supply and demand) where
both sides are voluntary market participants — neither side is an institutional payer
acting on behalf of the other. Both sides chose to be on the platform.

Key distinction from B2B2C: In a two-sided marketplace, the demand side pays because
they want the supply, not because an institution is subsidizing access. Neither side
is being "provided a benefit" by a third party — they transact on their own terms.

Key distinction from SaaS: The platform does not sell software — it sells access to
the other side of the market. Value comes from liquidity, not from features.

---

## The Seven Dimensions (Two-Sided Marketplace Lens)

### 1. Demand Side
- Who are the buyers, and what are they trying to accomplish?
- What is their purchase frequency — one-time, recurring, habitual?
- How price-sensitive is demand? Does elasticity change at different price points?
- What is the cost of the outside option (going direct to supply without the platform)?
- How much of demand comes from search/discovery vs. repeat/habitual use?

### 2. Supply Side
- Who are the providers, and what do they get from the platform beyond transactions?
  (Demand access, marketing, payments, scheduling, insurance, compliance tools)
- How concentrated is supply? Are there a few dominant providers or a long tail?
- What is the supply side's outside option — can they sell direct, use another platform,
  or operate offline?
- What is the cost of multi-homing (being on multiple platforms simultaneously)?
- Does supply quality improve or degrade as the platform scales?

### 3. Liquidity Dynamics
- What is the minimum viable market — the smallest geography or category where
  supply and demand are dense enough for the platform to work?
- What drives liquidity — supply-side density first, demand-side density first, or
  simultaneous build (the "cold start problem")?
- Where does the platform break — what supply:demand ratio causes the experience
  to degrade for one side?
- Is liquidity local (needs density in a specific geography) or global (network is
  indifferent to location)?

### 4. Take Rate Structure
- Which side pays the rake, and why that side?
- What is the basis for the take rate — percentage of transaction, flat fee per
  transaction, subscription for access, or freemium for one side?
- What forces compress the take rate over time (competition, supply-side leverage,
  regulatory pressure)?
- What allows the take rate to expand (more value-added services, demand monopoly,
  supply dependency)?
- Is there float — does the platform hold money between transaction and payout,
  generating yield?

### 5. Network Effects
- Are network effects same-side (more supply makes supply side better), cross-side
  (more supply makes demand side better and vice versa), or both?
- Is the network effect global (every new user makes the platform better for everyone)
  or local (density matters only within a geography or category)?
- What is the network effect ceiling — is there diminishing return from adding
  more supply or more demand beyond a threshold?
- What breaks the network effect: fragmentation, winner-takes-all consolidation,
  platform bypass, or side-switching?

### 6. Failure Modes Specific to Two-Sided Marketplaces
- **Disintermediation:** Supply and demand connect directly once they know each other,
  bypassing the platform and its rake
- **Multi-homing commoditization:** Both sides use multiple platforms simultaneously,
  eliminating the platform's pricing power
- **Supply-side platform capture:** Supply side builds its own demand channel and
  exits the platform (e.g., a hotel chain building direct booking)
- **Winner-takes-all consolidation:** A larger, better-capitalized platform achieves
  dominant liquidity, making competition structurally impossible
- **Race to zero on take rate:** Competition among platforms compresses rake below
  the cost of trust/compliance infrastructure
- **Regulatory fragmentation:** Regulators impose rules that advantage incumbents or
  require local compliance that destroys unit economics

### 7. Scale Dependencies
- What supply density threshold must be reached before demand acquisition is efficient?
- Is the platform dependent on a specific payment, identity, or trust infrastructure?
- Does the platform require regulatory approval (licensing, labor classification, etc.)
  before it can operate in a new market?
- What data volume is required for matching/recommendation to be meaningfully better
  than alternatives?

---

## Output Format for Extracted DNA

```
## Seed DNA: [Company Name] — Two-Sided Marketplace

**Demand side:** [Who, frequency, price sensitivity, outside option]
**Supply side:** [Who, concentration, multi-homing cost, outside option]
**Liquidity:** [Minimum viable market, cold start approach, breaks at what ratio]
**Take rate:** [%, from which side, compression/expansion forces, float?]
**Network effects:** [Type, local vs. global, ceiling, what breaks it]
**Failure modes:** [Top 2-3 most likely]
**Scale dependencies:** [What density/infrastructure/approval must come first]
**Exclude from search:** [Seed company's own domain]
```

---

## Search Heuristics for Two-Sided Marketplace Analogs

Look for:
- **Same liquidity structure in different verticals:** Who else faced the same
  cold-start problem in a different category? How did they seed supply before demand?
- **Same take rate tension:** Who else negotiates between a fragmented supply side
  and an aggregated demand side? Where did the rake ultimately settle?
- **Same disintermediation risk profile:** Who else operates in a market where supply
  and demand can recognize each other and go direct after one transaction?
- **Same regulatory exposure:** Who else has had to navigate labor classification,
  licensing, or consumer protection rules that redefined their model?

## What NOT to Search For

- B2B2C models (one side is an institutional payer, not a market participant)
- SaaS platforms (value is software features, not liquidity/matching)
- Single-sided networks (social networks, content platforms — no transaction between
  two distinct market sides)
