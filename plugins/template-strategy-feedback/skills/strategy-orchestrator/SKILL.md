---
name: strategy-orchestrator
description: >
  Orchestrates multi-step strategy sessions using the plugin's full toolkit. Trigger
  on: "strategy session", "full strategic analysis", "help me think through", "which
  tool should I use", or any request spanning multiple analytical lenses. Primarily
  a router - most questions need 1-2 skills, not a full session.
---

## PURPOSE

This skill is the entry point and router for the strategy-feedback plugin. It serves two functions:

1. **Router:** When someone has a strategic question but doesn't know which skill to use, recommend the right tool(s) and sequence.
2. **Orchestrator:** When someone wants a comprehensive analysis, run a multi-step strategy session using multiple skills in sequence.

## COMPANY CONTEXT

Before any analysis, identify the target company using the competitive-intel skill's multi-company routing:
- Check `skills/competitive-intel/companies/` for configured companies (excluding `_template`)
- If none: operate generically and suggest setting up company context
- If one: load automatically
- If multiple: ask which company (or match from the question)

## AVAILABLE TOOLS IN THIS PLUGIN

| Skill | What It Does | Best For |
|-------|-------------|----------|
| Strategy Council | 3-5 personas debate the strategic merits | "Should we build/price/pursue this?" |
| Buyer Persona Council | 3-5 buyer voices react to messaging/positioning | "How does this land with buyers?" |
| Strategy Frameworks | 14 analytical frameworks applied systematically | "What does a framework tell us about this?" |
| Competitive Intel | Current competitive landscape, strategic decisions, market context | "What's the competitive context?" |

**Frameworks available** (referenced in sequences below):

| Category | Frameworks | Use When |
|----------|-----------|----------|
| Advantage | 7 Powers, Porter's Five Forces, Aggregation Theory, Moats & Flywheels, Leaky Bucket | "Where's the advantage? Is it durable?" |
| Product | Jobs to Be Done, Blue Ocean / Value Curve | "What should we build? How do we position it?" |
| Growth | Crossing the Chasm, SaaS vs. Marketplace, Reverse-Engineered P&L | "How do we grow? Does the math work?" |
| Decision | Disruptive Innovation, Three Horizons, MECE Issue Trees | "How do we decide? How do we allocate?" |
| Synthesis | Minto Pyramid Principle | "How do we structure the argument?" |

"Load Competitive Intel" in any sequence below means: run the Competitive Intel skill to pull
current competitive landscape, strategic decisions, and market context relevant to the question.
This is always step 1 because everything else needs market grounding.

## ROUTING LOGIC

When someone asks a strategic question, determine the right tool(s):

### Single-skill questions (route directly)

- "How would a buyer react to this?" - Buyer Persona Council
- "Apply 7 Powers to our product" - Strategy Frameworks
- "What's our competitive landscape?" - Competitive Intel
- "Should we build or buy this capability?" - Strategy Council

### Multi-skill sequences (orchestrate)

#### Sequence 1: New Product Evaluation

Best for: "Should we build this? Is this a good bet?"

1. Load Competitive Intel for market grounding
2. Apply MECE Issue Trees to decompose the question
3. Apply relevant analytical frameworks (7 Powers for advantage, Crossing the Chasm for sequencing, Reverse-Engineered P&L for the math)
4. Run Strategy Council (3-5 relevant personas)
5. Run Buyer Persona Council for buyer reaction
6. Apply Minto Pyramid to structure the recommendation

#### Sequence 2: Competitive Positioning

Best for: "How do we differentiate? How do we displace a competitor?"

1. Load Competitive Intel
2. Apply Blue Ocean / Value Curve to map positioning
3. Apply Aggregation Theory to assess platform dynamics
4. Run Buyer Persona Council (how does our positioning land?)
5. Apply Minto to structure the positioning narrative

#### Sequence 3: Pricing Analysis

Best for: "Is this the right pricing model? How should we price this?"

1. Load Competitive Intel
2. Apply Reverse-Engineered P&L to test the math
3. Run Strategy Council (finance, investor, commercial voices)
4. Run Buyer Persona Council (budget owners, financial skeptic)

#### Sequence 4: Market Entry / Expansion

Best for: "Should we enter this market? How do we expand?"

1. Load Competitive Intel and Market Context
2. Apply Three Horizons to position this in the portfolio
3. Apply Crossing the Chasm for sequencing
4. Apply Leaky Bucket to assess network defensibility
5. Run Strategy Council

#### Sequence 5: Strategic Narrative / Board Prep

Best for: "Help me structure this argument for the board/exec team"

1. Load Competitive Intel for grounding
2. Apply MECE to decompose the question
3. Apply relevant analytical framework(s)
4. Apply Minto Pyramid to structure the output
5. Optionally run Strategy Council voices as a final pressure-test

#### Sequence 6: Full Strategic Deep Dive

Best for: "Give me everything - the complete analysis"

1. Load Competitive Intel
2. MECE decomposition
3. Apply 2-3 relevant analytical frameworks
4. Run Strategy Council (full 5-persona session)
5. Run Buyer Persona Council (3-5 relevant voices)
6. Minto synthesis of the complete analysis

Note: This is the heavy-duty option. Only run all six steps when the question truly warrants it.

#### Sequence 7: Competitive Advantage & Defensibility

Best for: "Does this product have a real moat? What's our sustainable advantage?"

1. Load Competitive Intel (who could threaten us and how)
2. Apply 7 Powers (assess each source of advantage systematically)
3. Apply Leaky Bucket (stress-test network effects)
4. Apply Moats & Flywheels (map the reinforcing loop)
5. Run Strategy Council (investor and finance voices debate durability)
6. Apply Minto to structure the moat narrative

## MULTI-SEQUENCE ORCHESTRATION

Many real questions span multiple sequences. When that happens:

**Identify the primary and secondary sequences.** The primary matches the core question; the secondary adds a supporting lens.

**Deduplicate shared steps.** If both sequences call for Competitive Intel, load it once. Never repeat a step just because two sequences list it.

**Thread outputs forward.** The primary sequence's analytical output feeds into the secondary. The second sequence synthesizes, it doesn't re-analyze.

**Typical blends:**

| Primary | Secondary | Blend |
|---------|-----------|-------|
| Market Entry (Seq 4) | Board Prep (Seq 5) | Market Entry analysis then Minto structure then Council pressure-test |
| Pricing (Seq 3) | Competitive Positioning (Seq 2) | Competitive Intel then Value Curve then Reverse P&L then Council + Buyer Council |
| New Product (Seq 1) | Defensibility (Seq 7) | MECE then relevant frameworks + 7 Powers then Council then Minto |

**Rule of thumb:** A blended sequence should have 4-6 steps total, not 8-12. If you're running more than 6 steps, break the question into two sessions.

## HOW TO RUN A SESSION

### 1. Clarify the Question

Before launching any analysis, make sure the question is specific enough.

- Too broad: "Should we invest in this product?"
- Actionable: "Should we expand this product to healthcare, given the competitive landscape and our current capacity?"

If the question is too broad, use MECE to decompose it first.

### 2. Load Context

Always start by loading Competitive Intel references for the target company. Then search for any recent context relevant to the specific question.

### 3. Pick the Right Sequence

Match the question type to one of the sequences above. If none fits perfectly, build a custom sequence.

### 4. Run Each Step

Execute each skill in sequence. The output of each step should inform the next. Don't run skills in isolation - thread the analysis through.

### 5. Synthesize

After all steps complete, provide a synthesis that:

- States the core recommendation (Minto: lead with the answer)
- Highlights the 3-5 most important tensions or trade-offs surfaced
- Names the specific decisions the asker needs to make
- Identifies what's still unknown and how to find out

## WHEN NOT TO ORCHESTRATE

Sometimes people just need one tool. Don't over-engineer it:

- If someone names a specific council or framework, just run that one.
- If the question is clearly about buyer reaction, go straight to Buyer Persona Council.
- If someone just wants to structure an argument, go straight to Minto.
- Only orchestrate when the question genuinely spans multiple analytical dimensions.

## NAVIGATION HELP

If someone is new to this plugin, explain the toolkit briefly:

"This plugin has four tools: two advisory councils that debate your question from different perspectives (Strategy Council for 'should we do this?' and Buyer Persona Council for 'how does this land with buyers?'), a frameworks library with 14 analytical lenses you can apply, and a competitive intel layer that keeps everything grounded in current market reality. Tell me what you're thinking through and I'll recommend the right approach."

## EXECUTION CHECKLIST

When running a session:

- Confirm the strategic question is specific and actionable
- Load competitive context or recent market intelligence
- Select the appropriate sequence (or build custom)
- Run each step in order, threading outputs forward
- Capture tensions and trade-offs as they emerge
- Synthesize with clear recommendation and next steps
- Name what is still unknown and how to validate
