# DNA Extraction Template: Generic (Universal Fallback)

Use this when the seed company's model does not match any of the typed archetypes,
or when the question spans multiple model types.

The goal of DNA extraction is to produce a precise search filter — not a business
description. Agents without a precise filter produce generic lists. Agents with one
produce targetable analogs.

---

## The Seven Dimensions

Extract each dimension for the seed company before launching any agent. Be specific.
"They sell software to enterprises" is not useful. "They sell a workflow automation
tool to VP-level buyers in logistics, purchased against an ops budget, with $50K-200K
ACV and 18-month payback" is useful.

### 1. Payer Structure
- Who pays, and what organizational role controls the budget?
- Why do they pay — cost reduction, risk reduction, compliance, competitive advantage,
  or talent/retention?
- How recurring is the payment? One-time, subscription, transaction-based?
- What is the buyer's alternative to not paying (build, ignore, use a competitor)?

### 2. Value Delivery
- What actually delivers the value to the end beneficiary?
- Who produces or provides the underlying product or service?
- Is delivery proprietary (the company builds and delivers it) or aggregated (the
  company orchestrates third-party supply)?
- How does quality of delivery scale — does it get better or worse as volume grows?

### 3. Revenue Structure
- What is the revenue model: take rate, subscription, licensing, services, outcome-based?
- If take rate: what percentage of what transaction? What determines the ceiling?
- What is the unit of monetization (per seat, per transaction, per outcome, per user)?
- What is the blended gross margin profile at scale?

### 4. Moat Mechanic
- What makes the position harder to displace as scale increases?
- Data accumulation, switching costs, supply lock-in, regulatory approval,
  network effects, brand, or proprietary methodology?
- How long does the moat take to build? What is the minimum scale for it to matter?

### 5. Network and Data Effects
- Does the product get more valuable as more users or transactions are added?
- Is the network effect same-side (more buyers attract more buyers), cross-side
  (more buyers attract more sellers), or data-compounding (more transactions produce
  better intelligence)?
- What breaks the network effect (fragmentation, side-switching, platform bypass)?

### 6. Failure Modes
- What are the three most likely structural failure modes for this model?
- Common failure modes by model type:
  - Supply commoditization (supply side can go direct or substitute)
  - Regulatory ceiling (regulated industry caps take rate or restricts model)
  - Disintermediation (buyer and seller connect directly once they know each other)
  - Margin compression (competition compresses take rate faster than volume grows)
  - Demand-side substitution (end user finds an alternative path to the same outcome)
  - Platform consolidation (a larger platform absorbs the category)

### 7. Scale Dependencies
- What must be true for this model to work at scale that is not yet true?
- Supply-side density, regulatory approval, data volume, employer network, brand recognition?
- What is the order-of-operations constraint — what has to happen first?

---

## Output Format for Extracted DNA

Write the extracted DNA as a compact reference block. Agents will use this verbatim
as their search filter.

```
## Seed DNA: [Company Name]

**Payer:** [Who pays, why, how recurring]
**Value delivery:** [What delivers it, proprietary vs. aggregated, scales how]
**Revenue:** [Model, unit, gross margin at scale]
**Moat:** [Primary moat mechanic, time to build, minimum scale]
**Network/data effects:** [Type, what breaks it]
**Failure modes:** [Top 2-3]
**Scale dependencies:** [What must be true first]
**Exclude from search:** [Seed company's own domain(s)]
```

---

## Adapting to Analog Search

Once DNA is extracted, translate each dimension into a search heuristic:

- Payer structure → search for companies with the same *type* of buyer
  (e.g., "institutional payer, individual beneficiary" or "employer-funded, worker-consumed")
- Value delivery → search for aggregated-supply vs. proprietary-delivery models
- Revenue structure → search by take rate range and transaction type
- Moat mechanic → search for companies that have built the same type of defensibility
- Failure modes → this is what to look for in "where has this model failed" research

Do NOT search for companies that look similar on the surface. Search for companies
that have the same structural DNA, even if they operate in completely different industries.
