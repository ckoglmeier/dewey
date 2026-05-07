---
name: competitive-intel
description: >
  Living competitive intelligence and strategic context layer. Maintains competitive
  landscape, strategic decisions, and market context for one or more companies.
  Grounds the Strategy Council, Buyer Persona Council, and Strategy Frameworks skills.
  Trigger on: "competitive intel", "what do we know about a competitor", "competitive
  landscape", "recent strategic decisions", "market context", "update competitive intel",
  "set up a new company", or any request for competitive or strategic context.
---

## Purpose

This skill serves three purposes:

1. **Direct queries:** Answer questions about competitive landscape, strategic decisions, and market context
2. **Context layer:** Provide grounding reference material for other skills in this plugin (Strategy Council, Buyer Persona Council, Strategy Frameworks)
3. **Company management:** Set up and maintain company contexts so the plugin works for one or more organizations

## Multi-Company Routing

This plugin supports multiple company contexts. Company data lives in `skills/competitive-intel/companies/` with one directory per company.

### When a user triggers any skill in this plugin:

1. **Check for configured companies.** List the directories under `skills/competitive-intel/companies/` (excluding `_template`).

2. **If no companies are configured:**
   - Respond generically to the strategic question using publicly available knowledge and web search
   - After answering, suggest: "This plugin supports company-specific context that makes the analysis much sharper. Want me to set up a company profile? I'll walk you through it."

3. **If exactly one company is configured:**
   - Load that company's context automatically. No need to ask.

4. **If multiple companies are configured:**
   - Ask: "Which company context should I use for this? I have: [list company names]"
   - Wait for the user to choose before proceeding
   - If the user's question clearly names or references a specific company, match it automatically without asking

## Setting Up a New Company

When asked to set up a new company (or when suggesting setup after a generic response):

1. Ask for the company name
2. Create a new directory: `skills/competitive-intel/companies/{company-name}/` (use kebab-case)
3. Copy all files from `_template/` into the new directory
4. Walk the user through populating each file, in this order:
   - **company-profile.md** — Start here. Ask about the company, products, buyers, mission. Fill in from what the user provides plus web search.
   - **competitive-landscape.md** — Ask about top competitors. Research and fill in.
   - **strategic-decisions.md** — Ask about current strategic priorities and recent decisions.
   - **market-context.md** — Research market size, trends, regulatory landscape.
   - **strategy-council-personas.md** — Help define 8-12 Strategy Council personas based on the company's decision-making context.
   - **buyer-personas.md** — Help define buyer personas and internal commercial voices.
5. Search Glean, Slack, and the web to enrich each file with real data
6. After setup, confirm: "Company context is ready. All skills in this plugin will now use [company name]'s context."

## How It Works

### When Triggered Directly
When asked about competitive intelligence or strategic context:
- Identify the target company (see routing above)
- Load that company's reference files (company-profile.md, competitive-landscape.md, strategic-decisions.md, market-context.md)
- Search Glean, Slack, and the web for the latest updates not yet in reference files
- Synthesize reference material with recent intelligence
- Flag if reference files are stale (>90 days old) and recommend updates
- If reference files are missing or empty, build context on the fly and recommend capturing it

### When Loaded by Other Skills
When another skill in this plugin requests context:
- Identify the target company (see routing above)
- Return that company's reference file contents as grounding material
- Note the "Last Updated" date from each file
- Allow other skills to ground their analysis in company-specific competitive and strategic context

## Reference Files (Per Company)

Each company directory contains six files:

1. **company-profile.md** — Company overview, products, buyers, brand principles
2. **competitive-landscape.md** — Competitors, positioning, win/loss patterns, displacement strategies
3. **strategic-decisions.md** — Strategic pillars, recent decisions, active debates
4. **market-context.md** — Market sizing, trends, buyer behavior, regulatory landscape
5. **strategy-council-personas.md** — Personas for the Strategy Council
6. **buyer-personas.md** — Personas for the Buyer Persona Council

See `_template/` for blank templates with guidance on what to include.

## Stale Data Alerts

If a reference file shows "Last Updated" older than 90 days:
- Flag that the context may be stale
- Recommend scheduling an update
- If possible, search Glean/Slack/web to surface major changes since last update

## If Reference Files Are Missing

If a reference file is missing or empty:
- Search available sources to build context on the fly
- Provide the best available synthesis
- Strongly recommend creating/updating the reference file
- Explain why maintained reference files improve decision quality across the plugin
