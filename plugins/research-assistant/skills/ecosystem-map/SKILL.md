---
name: ecosystem-map
description: >
  Map the ecosystem around a company, market, or platform - who the key players are,
  how they relate, where partnerships and dependencies exist, and where the power sits.
  Use when someone asks "map the ecosystem for [market]", "who are the key players
  around [platform]", "partnership landscape for [space]", "who should we be talking
  to in [ecosystem]", "map the value chain for [industry]", or any request to
  understand the web of companies, organizations, and relationships in a space. Can
  be invoked directly or via the research orchestrator.
---

# Ecosystem Map Research Type

**Standalone execution:** If invoked directly (not via the research orchestrator),
follow the protocol in `../research/references/standalone-execution.md` to run the
full pipeline: company context -> internal recon -> plan -> launch agents -> monitor ->
synthesize.

Use this type when the goal is to map the ecosystem - understanding who the players
are, how they relate to each other, where partnerships exist, where dependencies
create risk, and where opportunities exist.

**Important distinctions:**
- **Ecosystem Map vs. Competitive Analysis:** Competitive analysis focuses on rivals.
  Ecosystem mapping includes partners, suppliers, distributors, complementary players,
  and other non-competitive relationships. Many ecosystem players are potential allies,
  not competitors.
- **Ecosystem Map vs. Technology Landscape:** Technology landscape maps tools in a
  category (buyer perspective). Ecosystem map maps the web of relationships and
  dependencies around a market or platform (strategic perspective).
- **Ecosystem Map vs. Build/Buy/Partner:** B/B/P evaluates specific capability
  decisions. Ecosystem mapping provides the map from which partnership targets
  are identified.

---

## When to Use This Type

- "Map the ecosystem around [market/platform/industry]"
- "Who are the key players we should know in [space]?"
- "What does the value chain look like for [industry]?"
- "Where are the partnership opportunities in [market]?"
- "Who has power/leverage in the [category] ecosystem?"

---

## Recommended Agent Workstreams

For most ecosystem maps, plan 2-3 agents:

**Agent 1: Ecosystem Structure**
Sections:
1. Ecosystem definition - what's the boundary of this ecosystem? What's in scope
   and what's adjacent? Define the value chain or platform structure.
2. Player categories - organize the ecosystem into layers or roles. Common
   categories: platforms, infrastructure providers, application builders, service
   providers, integrators, channel partners, end buyers, regulators.
3. Key players by category - for each category, name the 3-5 most important
   players with a one-line description of their role and scale.
4. Value flow - how does value (money, data, users, products) flow through this
   ecosystem? Who pays whom? Where does margin concentrate?

**Agent 2: Relationship Mapping**
Sections:
1. Partnership landscape - existing partnerships between ecosystem players.
   Who is partnered with whom? What form do partnerships take (integration,
   co-selling, OEM, referral, data sharing)?
2. Dependency analysis - who depends on whom? Which players are "kingmakers"
   that others need access to? Which players are replaceable?
3. Power dynamics - where does leverage sit? Who controls the bottleneck?
   Platform owners, distribution gatekeepers, regulatory gatekeepers, or
   supply-constrained players?
4. Competitive tensions within the ecosystem - where do partners also compete?
   Where are alliances fragile?

**Agent 3: Strategic Opportunities**
Sections:
1. Partnership opportunities - based on the map, which relationships would be
   most valuable for the company? Rank by strategic value and feasibility.
2. Ecosystem gaps - what roles are underserved? Where is there an opportunity
   for a new player or a new type of partnership?
3. Risk assessment - which ecosystem dependencies could hurt the company?
   Platform risk, channel concentration, regulatory gatekeepers?
4. Recommended ecosystem strategy - how should the company position itself
   within this ecosystem? Build relationships, acquire position, or create
   an alternative path?

---

## Ecosystem Power Framework (REQUIRED)

Every ecosystem map must assess where power sits. For each major player or
category, evaluate:

### Power sources:
- **Platform control** - owns the platform others build on. Can change rules,
  extract rent, or de-platform participants.
- **Distribution control** - controls access to end customers. Others need them
  to reach buyers.
- **Data advantage** - accumulates data that others need or that creates switching
  costs.
- **Regulatory position** - holds licenses, certifications, or regulatory
  relationships that others can't easily obtain.
- **Supply scarcity** - provides something in limited supply (talent, technology,
  content, inventory) that others need.
- **Standard setting** - defines the technical or commercial standards others
  must follow.

### Power classification:
- **Dominant** - controls the ecosystem; others must work within their rules
- **Influential** - shapes ecosystem direction; has leverage but not control
- **Participant** - operates within the ecosystem; limited ability to shape it
- **Dependent** - relies on the ecosystem but has little leverage; vulnerable
  to changes by dominant players

State the classification and evidence for the 5-8 most important players.

---

## Relationship Mapping Protocol (REQUIRED)

When documenting relationships between ecosystem players, be specific:

For each significant relationship:
- **Players involved** - who is partnered with whom?
- **Relationship type** - integration, co-selling, OEM, referral, data sharing,
  investment, board seat, shared customer base
- **Depth** - is this a deep strategic partnership or a lightweight integration?
  How much revenue or activity flows through it?
- **Stability** - is this relationship stable, strengthening, or at risk? What
  could disrupt it?
- **Exclusivity** - is this exclusive? Could either party replicate it with
  a competitor?

---

## Key Data Sources

- **Company partnership pages** - most companies list integration partners,
  technology partners, and channel partners on their websites
- **Press releases** - partnership announcements, joint customer wins
- **Crunchbase / PitchBook** - investment relationships (who invested in whom
  creates implicit ecosystem ties)
- **API directories and marketplace listings** - who integrates with whom
  technically (e.g., Salesforce AppExchange, AWS Marketplace)
- **Industry association membership** - who participates in the same standards
  bodies or trade groups
- **Conference speaker/sponsor lists** - who shows up at the same events
- **Job postings** - mention of specific tools or partnerships reveals
  real ecosystem relationships

---

## Output Structure for Synthesis

1. **Ecosystem thesis** - 2-3 sentences: what is this ecosystem, how is it
   structured, and where does power sit?
2. **Ecosystem map** - organized by player category. For each category: key
   players, their role, scale, and power classification.
3. **Value chain** - how value flows through the ecosystem. Who pays whom,
   where margin concentrates, where bottlenecks exist.
4. **Relationship map** - key partnerships and dependencies. Table or prose
   organized by relationship type.
5. **Power analysis** - who controls what, and what that means for new entrants
   or participants trying to grow their position.
6. **Strategic implications** - specific partnership targets, ecosystem risks,
   and recommended positioning for the company.

---

## Common Pitfalls

- **Listing players without mapping relationships.** A list of companies is not
  an ecosystem map. The value is in understanding how they connect.
- **Missing the power dynamics.** An ecosystem map that treats all players as
  equal misses the most important insight: who has leverage.
- **Ignoring indirect relationships.** Two companies may not partner directly
  but share investors, customers, or technology dependencies. These indirect
  ties matter.
- **Static snapshot.** Ecosystems evolve. Note which relationships are
  strengthening, which are at risk, and what forces are reshaping the map.
- **No strategic implications.** An ecosystem map without "here's what you
  should do" is a reference document, not research.
