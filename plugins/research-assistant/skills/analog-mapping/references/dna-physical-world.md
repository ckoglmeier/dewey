# DNA Extraction Template: Physical-World / Hardware + Data

Use when the seed company deploys a physical asset (sensor, device, vehicle, robot,
infrastructure) on customer premises or in the field, and the primary business value
comes from the data that asset generates — not from the hardware sale itself.

Key signal: The hardware is the means; the data intelligence is the product. Revenue
typically comes from recurring software/data subscriptions enabled by the deployed asset,
not primarily from hardware margins.

Key distinction from pure SaaS: There is a physical deployment step that creates a
barrier to entry (installation, maintenance, supply chain, field ops) and a data layer
that compounds with fleet size in ways that pure software cannot replicate without the
physical presence.

---

## The Seven Dimensions (Physical-World Lens)

### 1. Hardware / Deployment Model
- What physical asset is deployed? (Sensor, camera, drone, vehicle, embedded device,
  infrastructure component)
- On whose property or infrastructure is it deployed — customer's facility, public
  infrastructure, third-party asset?
- Under what access arrangement — sold outright, leased, installed as a service, or
  operated by the company?
- Who manages the physical asset over its lifetime — customer, company, third-party?
- What is the deployment cost, deployment time, and replacement cycle?

### 2. Data Layer
- What data does the asset collect, at what frequency, and in what format?
- How does the data compound in value as the fleet or network grows?
  (Comparative benchmarks, predictive models, anomaly detection, network coverage)
- Who else could collect this data without the hardware? (Satellite, manual inspection,
  competitor sensor, public data source)
- What is the latency requirement — does the data need to be real-time, or is
  batch/periodic sufficient?
- Does data quality improve with time (model training) or degrade (sensor drift,
  environmental wear)?

### 3. Revenue Structure
- Is primary revenue hardware sale, SaaS subscription on top of deployed hardware,
  outcome-based (savings or performance guarantees), or managed service?
- What is the ACV per deployed unit, and how does it scale with fleet size?
- What is the hardware gross margin vs. software/data gross margin? (Typically
  hardware at 30-50%, data/software at 70-80%)
- Is there a recurring revenue stream that outlasts the hardware deployment cycle?
- What is the payback period for the customer, and how is ROI demonstrated?

### 4. Moat Mechanic
- What makes the installed base defensible once deployed?
  (Switching cost of ripping out hardware, proprietary data format, integration
  with customer systems, multi-year contracts, regulatory certification)
- Does the data get more valuable as fleet density increases in a given geography
  or within a given customer?
- Is there a certification, safety standard, or regulatory approval that creates
  a barrier for new entrants?
- How hard is it for a competitor to replicate the installed base — cost, time,
  access requirements?

### 5. Network and Data Effects
- Does a larger fleet produce better intelligence than a smaller fleet?
  (Cross-fleet benchmarking, aggregate anomaly detection, predictive maintenance models)
- Is there a network density threshold below which the data is not meaningfully
  better than alternatives?
- Does intelligence transfer from one customer's fleet to another's (cross-customer
  learning), or is each deployment siloed?

### 6. Failure Modes Specific to Physical-World Models
- **Hardware commoditization:** The sensor/device becomes a commodity; competitors
  offer the same hardware at cost, making the data layer the only differentiator —
  and that can be replicated without the hardware
- **Customer vertical integration:** Large customers build or acquire the capability
  internally (e.g., a major utility buys the sensor company)
- **Platform substitution:** A broader industrial IoT platform offers the same
  sensing + data layer as one module of a larger system
- **Field ops cost creep:** Installation, maintenance, and replacement costs
  compress margins faster than software revenue grows
- **Data access regulation:** Regulators mandate data portability or open APIs,
  removing the data lock-in moat
- **Physics disruption:** A new sensing modality (cheaper satellite imagery,
  AI-enhanced mobile cameras) makes the dedicated hardware unnecessary

### 7. Scale Dependencies
- What installed base size is required for predictive models to be meaningfully
  accurate?
- Is there a geographic density threshold for the data to be actionable?
- What field operations infrastructure (installation network, maintenance crews,
  supply chain) must be in place before scaling is efficient?
- Does the company need a certified/approved status before deploying in regulated
  industries (utilities, aviation, healthcare)?

---

## Output Format for Extracted DNA

```
## Seed DNA: [Company Name] — Physical-World / Hardware + Data

**Hardware:** [What asset, deployed where, under what arrangement, who maintains]
**Data layer:** [What data, frequency, how it compounds, who else could collect it]
**Revenue:** [Hardware margin vs. software margin, ACV per unit, payback period]
**Moat:** [Primary mechanism — install base, data format, certification, integration]
**Network/data effects:** [Cross-fleet learning, density threshold, siloed vs. shared]
**Failure modes:** [Top 2-3 most likely]
**Scale dependencies:** [Fleet size, geographic density, field ops, regulatory approval]
**Exclude from search:** [Seed company's own domain and adjacent verticals]
```

---

## Search Heuristics for Physical-World Analogs

Look for:
- **Same deployment model in a different vertical:** Who else put a sensor on a
  customer's asset, owns the data relationship, and charges for intelligence? Look
  across: agriculture, construction, energy/utilities, mining, maritime, aviation,
  insurance-adjacent sensing, environmental monitoring.
- **Same hardware-as-wedge strategy:** Who else used low-margin hardware to build
  a high-margin data subscription business?
- **Same customer ROI structure:** Who else sells a "pay for outcomes" model
  where the hardware is justified by measurable cost savings?
- **Same moat-building path:** Who else went from point-sensor to fleet intelligence
  to industry benchmark? At what fleet size did the intelligence become defensible?

## What NOT to Search For

- Pure software companies that happen to use IoT data (use dna-saas-platform.md)
- Consumer hardware (different buyer, different economics, different distribution)
- Manufacturing equipment (the machine is the product, not the sensor layer)
