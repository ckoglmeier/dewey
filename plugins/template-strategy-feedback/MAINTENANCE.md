# Maintaining the Strategy-Feedback Plugin

## Why Maintenance Matters

The councils and frameworks are durable — they don't go stale. But the competitive intel and strategic context layer does. If reference files are more than 90 days old, the councils are debating with outdated information. The skills compensate partially by searching available tools for recent context, but reference files are the baseline that ensures consistency.

## What to Update and When

### Quarterly (Every 3 Months)

**competitive-landscape.md** (per company)
- Review and update each competitor section
- Add any new competitors or emerging threats
- Update "Recent moves" for each competitor
- Refresh win/loss patterns
- Owner: Strategy or Competitive Intel team

**market-context.md** (per company)
- Update market size estimates if new data available
- Refresh key trends sections
- Update regulatory/policy changes
- Refresh buyer behavior observations
- Owner: Strategy or Market Research team

### After Major Events

**strategic-decisions.md** (per company)
- Update after any major strategic decision: new product launch, pricing change, market entry/exit, M&A activity, major org change
- Move resolved debates from "Under Active Debate" to "Recent Major Decisions"
- Move abandoned initiatives to "Reversed or Abandoned" with learnings
- Owner: Whoever made or communicated the decision

### Annually

**Council personas** (both strategy-council-personas.md and buyer-personas.md)
- Review buyer segments: Are the ICPs still right?
- Review objections: What new objections are reps hearing?
- Review competitive displacement narratives: Still accurate?
- Add new personas if the company enters new verticals or segments
- Owner: Plugin owner + Commercial teams

**Strategy Frameworks**
- Add new frameworks the team has adopted
- Remove frameworks nobody invokes
- Owner: Whoever uses this plugin most

## How to Update

### Reference Files

Reference files are plain markdown in `skills/competitive-intel/companies/{company-name}/`. To update:

1. Open the relevant `.md` file
2. Update the content
3. Update the "Last Updated" date and "Updated By" fields at the top
4. Add an entry to the Changelog table at the bottom
5. Save

### Council Personas

Personas live in the company directory:
- Strategy Council: `strategy-council-personas.md`
- Buyer Persona Council: `buyer-personas.md`

### Framework References

Framework reference files are in `skills/strategy-frameworks/references/`. Each framework is a separate `.md` file. These are generic and rarely need updating.

## Setting Up a Maintenance Reminder

Recommended: set up a quarterly reminder that pings the plugin owner:

"Time to update the Strategy-Feedback plugin. Check each company's:
- competitive-landscape.md — any competitor moves in the last 90 days?
- strategic-decisions.md — any major decisions made?
- market-context.md — any market shifts worth noting?
Files are in skills/competitive-intel/companies/{company-name}/"

## Staleness Indicators

The plugin skills check the "Last Updated" date on reference files. If files are >90 days old, the skills flag this to the user and rely more heavily on real-time search for current context. This is a safety net, not a substitute for regular updates.
