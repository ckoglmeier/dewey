# Classroom telemetry

Classroom logs usage events locally so skill maintainers can see which skills are actually used and which are abandoned. The log is on your machine, never sent anywhere by default.

## What gets logged

Events are appended to `~/.claude/classroom-analytics.log` as JSONL (one JSON object per line):

| Event | When |
|---|---|
| `first_run` | The first time you open Claude Code after installing Classroom |
| `refresh_success` | Background cache refresh succeeded |
| `refresh_failure` | Background cache refresh failed (network, checksum, etc.) |
| `guide_recommend` | Guide completed a path recommendation |
| `skill_install` | You confirmed installing a plugin |
| `skill_invoke` | Guide routed you to a specific skill |
| `extension_created` | You created a local skill extension via `/classroom extend`. Carries enriched fields (`parent`, `parent_plugin`, `additions`, `tools_added`, `user_intent`) that feed the central learning loop — see [extension-telemetry.md](extension-telemetry.md) |
| `schedule_created` | You scheduled a skill via `/classroom schedule` |

Example log entries:

```jsonl
{"ts":"2026-05-06T14:23:00Z","event":"first_run"}
{"ts":"2026-05-06T14:24:00Z","event":"guide_recommend","path":"sales-ae","plugins":["sales-enablement","competitive-intelligence"]}
{"ts":"2026-05-06T14:25:00Z","event":"skill_install","skill":"sales-enablement","via":"recommend"}
{"ts":"2026-05-06T14:26:00Z","event":"skill_invoke","skill":"stakeholder-followup"}
{"ts":"2026-05-06T14:27:00Z","event":"extension_created","parent":"stakeholder-followup","extension":"acme-stakeholder-followup"}
{"ts":"2026-05-06T14:30:00Z","event":"refresh_success","url":"https://github.com/ckoglmeier/classroom/archive/main.tar.gz"}
```

## Reading your analytics

Run `/classroom analytics` to get a summary: most-used skills, installed-but-unused plugins, and the last refresh time.

Or read the raw log:

```bash
cat ~/.claude/classroom-analytics.log
```

## Opt out

Set `CLASSROOM_TELEMETRY=0` in your shell profile and events will not be written:

```bash
# ~/.zshrc or ~/.bashrc
export CLASSROOM_TELEMETRY=0
```

The analytics log file itself is not created on first install if telemetry is disabled.

## Forwarding to a central endpoint (opt-in)

If your company runs a Classroom instance and wants aggregated analytics, set:

```bash
export CLASSROOM_TELEMETRY_ENDPOINT=https://your-internal-analytics.example.com/classroom
```

When set, the Guide will POST the contents of the local log to that endpoint on session end, then truncate the local log. Before sending, the log is filtered through `~/.claude/classroom-telemetry.sh strip-bodies` which removes the prose fields (`additions`, `user_intent`) from `extension_created` events unless `CLASSROOM_TELEMETRY_FORWARD_BODIES=1` is also set. See [extension-telemetry.md](extension-telemetry.md) for the full privacy model.

This is intentionally simple — no SDK, no vendor dependency. Your endpoint is responsible for ingestion, deduplication, and storage.

## Privacy

Three layers, evaluated in order:

1. **Global opt-out** — `CLASSROOM_TELEMETRY=0` suppresses everything; the log file isn't even created.
2. **Per-plugin / per-skill opt-out** — `telemetry: false` in `plugin.json` or SKILL.md frontmatter suppresses all events for that scope at capture time.
3. **Body-forwarding opt-in** — `CLASSROOM_TELEMETRY_FORWARD_BODIES=1` allows the user-authored prose in `extension_created` events to leave the machine. Off by default.

Other notes:

- No personally identifiable information is logged by default. Events contain skill names, paths, and (with body forwarding) user-authored extension content.
- The log is local. It lives at `~/.claude/classroom-analytics.log` and is only readable by you.
- Forwarding requires the explicit `CLASSROOM_TELEMETRY_ENDPOINT` env var.
- To delete all local analytics: `rm ~/.claude/classroom-analytics.log`
