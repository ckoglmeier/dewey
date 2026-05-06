# Extension telemetry — the central learning loop

Classroom captures structured events when users create local extensions of central skills, then forwards them (opt-in) to a central endpoint. This is the data layer for a future hosted aggregator that will analyze patterns across users and propose canonical updates.

**Local Classroom only captures and forwards. It does not analyze or recommend.** That's deliberate. Aggregation, pattern detection, and recommendation generation belong to the hosted side, not every user's machine.

## Why this matters

When ten users all extend `weekly-status-update` to add a Slack lookup before drafting, that's the highest-quality signal you can get that the canonical is missing a step. Better than session frustration, better than invoke counts. The user *wrote* the extension, *uses* it, and *got value* from it.

Aggregating those signals lets central skill maintainers absorb proven patterns into the canonical, so every new user gets the upgrade automatically.

## Event schema

The richest event is `extension_created`, emitted by the Guide's `/classroom extend` flow:

```json
{
  "ts": "2026-05-06T14:27:00Z",
  "event": "extension_created",
  "parent": "stakeholder-followup",
  "parent_plugin": "sales-enablement",
  "parent_marketplace": "classroom",
  "extension": "acme-stakeholder-followup",
  "additions": "1. Pull last 5 Gong calls for the account...\n2. Append our team's battlecard.",
  "tools_added": ["Bash(gong *)", "mcp:linear"],
  "user_intent": "Add Gong evidence and our standard battlecard format"
}
```

| Field | Required | Description |
|---|---|---|
| `ts` | yes | UTC ISO-8601 timestamp |
| `event` | yes | Always `extension_created` for this event type |
| `parent` | yes | Name of the parent skill being extended |
| `parent_plugin` | yes | Plugin the parent lives in |
| `parent_marketplace` | yes | Always `classroom` (this is the filter that gates the emission) |
| `extension` | yes | Name of the new extension SKILL.md |
| `additions` | no | The user-authored body content of the extension (after "Then additionally:"). Sensitive — gated by body-forwarding opt-in |
| `tools_added` | no | Tools the user added in `allowed-tools` |
| `user_intent` | no | The one-line plain-language description the user gave when asked what they wanted to add. Sensitive — gated by body-forwarding opt-in |

Other events (`skill_install`, `guide_recommend`, `skill_invoke`, etc.) carry shallower fields and are documented in [telemetry.md](telemetry.md).

## Privacy model — three layers

Privacy is enforced at three layers, evaluated in this order:

### 1. Global opt-out — `CLASSROOM_TELEMETRY=0`

Set `CLASSROOM_TELEMETRY=0` in your shell profile and **nothing is logged anywhere**. The local analytics file isn't even created. This is the off switch.

### 2. Per-plugin / per-skill opt-out — `telemetry: false`

Skill authors can mark a plugin or individual skill as off-limits to telemetry. This is for sensitive domains like HR, legal, medical-adjacent workflows — anywhere even the *existence* of an extension would leak.

**Plugin-level** (covers all skills in the plugin), in `plugin.json`:

```json
{
  "name": "hr-onboarding",
  "description": "...",
  "telemetry": false
}
```

**Skill-level** (overrides plugin default for one skill), in `SKILL.md` frontmatter:

```markdown
---
name: medical-summary
description: ...
telemetry: false
---
```

Default for both is `true` (telemetry on). When `false`, no events about that scope are emitted at all — the gate runs at capture time, before the log is touched.

### 3. Body-forwarding opt-in — `CLASSROOM_TELEMETRY_FORWARD_BODIES=1`

The local log always contains the full event including `additions` and `user_intent`. But when the log is forwarded to a central endpoint via `CLASSROOM_TELEMETRY_ENDPOINT`, those two prose fields are **stripped by default**.

Forwarding still includes everything else:
- Counts: how many extensions of skill X
- Patterns in `tools_added`: what MCP servers / Bash commands users add
- Identity of the parent and the extension

That's enough to count and group, just not to read prose verbatim.

To allow the prose through (which is what enables semantic clustering of extension content for richer pattern detection), set:

```bash
export CLASSROOM_TELEMETRY_FORWARD_BODIES=1
```

The forwarder uses `~/.claude/classroom-telemetry.sh strip-bodies` to apply the strip — same logic everywhere.

## Helper script

Both capture and forwarding go through `~/.claude/classroom-telemetry.sh`:

```bash
# Emit an event (gated by all three layers above)
bash ~/.claude/classroom-telemetry.sh emit event=extension_created \
  parent=stakeholder-followup parent_plugin=sales-enablement \
  parent_marketplace=classroom extension=acme-stakeholder-followup \
  additions="..." tools_added="Bash(gong *),mcp:linear" user_intent="..."

# Strip bodies (used by the forwarder)
cat ~/.claude/classroom-analytics.log | bash ~/.claude/classroom-telemetry.sh strip-bodies
```

The helper is installed by `install.sh`. The Guide skill calls it at every emit site.

## What Classroom does NOT do locally

- No analysis of events
- No pattern detection
- No recommendation generation
- No PR drafting against the canonical
- No opening of issues or notifications

All of those belong to a future hosted aggregator that consumes the forwarded JSONL. Local Classroom is a thin data pipe.

## Contract for a future central aggregator

A central aggregator that ingests forwarded JSONL events should be able to do, with no body forwarding:

- Count extensions per parent skill (`group by parent_marketplace, parent_plugin, parent`)
- Find which canonical skills are getting extended most (signal: candidate for absorption)
- Group `tools_added` to surface common tool dependencies users are adding (e.g. *every fifth extension of `weekly-status-update` adds Slack — propose adding Slack as an optional canonical step*)

With body forwarding (opt-in):

- Cluster `additions` prose semantically to find recurring instruction patterns
- Use `user_intent` to label what users wanted from each extension cluster
- Generate suggested canonical patches with full prose evidence

The contract is simple: receive raw JSONL, deduplicate by `(ts, event, extension)`, and aggregate. There's no API, no SDK — the endpoint is whatever HTTP service consumes JSONL POSTs.

## Guidance for skill authors

Set `telemetry: false` on:

- HR, payroll, performance review skills
- Legal review or contract analysis skills
- Anything medical or health-adjacent
- Skills that run against confidential M&A or restructuring data
- Any skill where the *existence* of a personalized extension could itself leak (e.g. a skill named "draft-resignation-letter")

Default `telemetry: true` is appropriate for the bulk of business-use skills. The signal compounds across users; opting out by default leaves canonical maintainers blind.

## Related

- [telemetry.md](telemetry.md) — the broader analytics log, all events, opt-out
- [extending-skills.md](extending-skills.md) — the composition convention this telemetry observes
