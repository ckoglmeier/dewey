# Scheduling Dewey skills

Dewey does **not** ship its own scheduler. Every host where Dewey runs already has one, and they all do the job better than a wrapper around `cron` or `launchd`. Use the host-native scheduler.

## Where to schedule

| Host | Native scheduling | How |
|---|---|---|
| **Claude Code** | Routines (cloud-executed cron) | Use the `schedule` skill. Routines run remotely, so they fire whether your laptop is on or off. |
| **Cowork** | scheduled-tasks MCP | Create a scheduled task that invokes a Dewey skill. Local-machine-bound. |
| **Codex** | No native scheduler at the moment | If you need scheduling on Codex, use the OS scheduler directly (`crontab` / `launchd`) and have it call `codex exec /<skill>`. |

To run a Dewey skill on a schedule, point the host's scheduler at the skill name — e.g., a Routine that runs `/weekly-status-update` every Monday at 8am. The skill loads its required context, runs, and writes its output wherever the skill body says.

## How to schedule a Dewey skill from Cowork

Cowork's `scheduled-tasks` are themselves SKILL.md files. To schedule a Dewey skill, drop a thin wrapper at `~/.claude/scheduled-tasks/<wrapper-name>/SKILL.md`:

```markdown
---
name: weekly-status-monday
description: Draft my weekly status update every Monday morning.
---

Run /weekly-status-update for the engineering team and save the output to ~/Documents/weekly-updates/$(date +%Y-%m-%d).md.
```

Then register the wrapper with Cowork's scheduler (via the Cowork UI or the `scheduled-tasks` MCP). The scheduler runs the wrapper SKILL.md on its cadence; the wrapper invokes the Dewey skill. The Dewey skill in turn loads any `requires-context:` and produces its output.

Two things to know:
- The wrapper SKILL.md needs its own `name` field (separate from the Dewey skill it invokes) so Cowork doesn't collide names.
- If the Dewey skill needs context, the wrapper inherits the dependency — make sure the context plugin is also installed.

## Why Dewey doesn't own this

Earlier versions shipped a `dewey-schedule.sh` helper and a `/dewey schedule` Guide flow. We removed both because they reinvented what every host provides. The honest value Dewey could have added — conversational scheduling for non-technical users — is already covered by Cowork's native scheduler and Claude Code's Routines.

There is one slice of scheduling Dewey may eventually own: **org/team-managed scheduled distribution** (a team lead schedules a weekly competitor digest that goes to everyone with the `sales-ae` path; a centrally-built newsletter goes out every Friday with curated content). That's an org-layer feature and lives in the future hosted Dewey — not in this repo. See [roadmap.md](roadmap.md) under the Hosted Dewey bucket.

## What about telemetry?

The `schedule_created` telemetry event is gone with the helper. If we eventually need to know how many users schedule which Dewey skills via host-native schedulers, we'll need either (a) a hook into each host's scheduler, or (b) a convention where the scheduler runs a Dewey command that emits the event. Both are deferred until there's signal that the data matters.
