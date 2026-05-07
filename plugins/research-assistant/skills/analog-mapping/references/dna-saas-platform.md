# DNA Extraction Template: SaaS / B2B Platform

Use when the seed company sells software or a software-enabled service to business
buyers, where the primary value is workflow automation, data intelligence, or system
of record — not matching supply to demand (that's marketplace) or mediating between
an institution and an individual (that's B2B2C).

Key signal: The company's revenue comes primarily from software subscriptions or
platform fees, not from taking a cut of transactions between third parties. The
product is the software; the customer is a business.

Key distinction from marketplace: A SaaS company's customers pay for the software
itself, not for access to a network. Removing all other customers would not diminish
the product's core value to any given customer (unlike a marketplace, where liquidity
is the product).

---

## The Seven Dimensions (SaaS / B2B Platform Lens)

### 1. Buyer Structure
- Who buys — which role initiates, which role approves, which budget does it come from?
- Is this a bottom-up (end-user-led, PLG) or top-down (executive-led, enterprise)
  purchase motion?
- What is the ACV range and typical sales cycle length?
- What is the buyer's alternative: build internally, buy from a competitor,
  use a spreadsheet/manual process, do nothing?
- Is the purchase driven by pain (fixing something broken) or gain (enabling
  something new)?

### 2. End User and Adoption
- Who uses the software day-to-day — is it the same person who bought it?
- What is the adoption friction — how long until the product delivers value?
- What is the "aha moment" that converts a trialer into a committed user?
- What would the user do if the product disappeared tomorrow?
- Does the end user's usage pattern generate data that feeds back into the product?

### 3. Revenue Structure
- Is the primary revenue model seat-based, usage-based, outcome-based, or platform fee?
- What is the land ACV, and what is the typical expansion trajectory (NRR)?
- How does pricing scale — by seats, by usage volume, by module/feature, by outcome?
- What is the blended gross margin (typically 70-80%+ for pure SaaS)?
- Is there a services component — implementation, professional services, CSM?
  And at what margin?

### 4. Moat Mechanic
- What makes churn structurally unlikely as usage deepens?
- Data lock-in (company's data lives in the system), workflow integration (removing
  the product breaks core processes), network effects (other stakeholders use the
  same platform), regulatory/compliance entrenchment, or multi-year contract structure?
- How long does the moat take to build after initial deployment?
- What would it cost the customer to migrate away (not just financial — operational,
  data, retraining)?

### 5. Network and Data Effects
- Does the product get better for any customer as more customers use it?
  (Benchmarking, shared data models, cross-customer pattern recognition)
- Is there a within-company network effect — does adding more seats or departments
  compound the value?
- Does the data the product generates compound over time in a way that creates a
  defensible intelligence layer?

### 6. Failure Modes Specific to SaaS
- **Point-solution displacement:** A larger platform (HRIS, ERP, CRM) adds the
  capability as a feature and prices the point solution out
- **Buyer consolidation:** Buyers consolidate vendors under preferred platform
  relationships, and the product falls outside the shortlist
- **Open-source substitution:** The core functionality becomes commoditized in
  open-source, removing the pricing floor
- **PLG commoditization:** A competitor copies the core workflow and gives it away
  to acquire the install base, then upsells
- **Data portability regulation:** Regulatory changes force data interoperability,
  removing the migration switching cost
- **AI automation:** The workflow the software automates becomes directly doable
  with a general-purpose AI tool

### 7. Scale Dependencies
- What integration ecosystem must exist for the product to deliver its full value?
  (Salesforce ecosystem, HRIS connectors, payroll integrations, etc.)
- Is the product dependent on a data standard or protocol (HL7, EDI, OAuth) that
  requires ecosystem adoption?
- What onboarding investment must the customer make before the product sticks?
- Is there a minimum company size below which the product doesn't justify its cost?

---

## Output Format for Extracted DNA

```
## Seed DNA: [Company Name] — SaaS / B2B Platform

**Buyer:** [Role, budget, motion (PLG vs. top-down), ACV, sales cycle]
**End user:** [Who uses it, adoption friction, aha moment, what breaks without it]
**Revenue:** [Model, land ACV, NRR, gross margin, services %]
**Moat:** [Primary mechanism, time to build, migration cost]
**Network/data effects:** [Cross-customer, within-company, data compounding]
**Failure modes:** [Top 2-3 most likely]
**Scale dependencies:** [Ecosystem, integrations, minimum company size]
**Exclude from search:** [Seed company's own domain]
```

---

## Search Heuristics for SaaS Analogs

Look for:
- **Same buyer + same pain:** Who else sells to the same role with the same purchase
  motion in a different vertical? (e.g., "VP HR in mid-market manufacturing" → find
  who else cracks that buyer in a different category)
- **Same moat mechanic in a different domain:** Who else has built a data-lock moat,
  a workflow-integration moat, or a cross-customer benchmarking moat?
- **Same PLG vs. enterprise tension:** Who else navigated the transition from
  bottom-up viral adoption to enterprise contract sales?
- **Same platform-risk profile:** Who else faced the "will Salesforce/Workday/Microsoft
  build this as a feature?" question — and survived or didn't?

## What NOT to Search For

- Marketplace models (value is liquidity/matching, not workflow software)
- B2B2C models (an institution pays on behalf of an individual beneficiary)
- Hardware companies that happen to have a software layer (use dna-physical-world.md)
