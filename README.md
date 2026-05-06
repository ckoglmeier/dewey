# Classroom

**A plugin marketplace for Claude Code and Codex (working on Cowork!)**

Skills are authored once in standard `SKILL.md` format and run in either agent. When both are installed, Classroom mirrors its skills into Codex automatically — see [docs/codex-sync.md](docs/codex-sync.md).

## Why this exists

Everyone builds their own Claude Code skills right now, on their local machine. The entire system is living in single-player mode — we don't learn, we don't collaborate, and we have constant errors from binaries shared in Slack, email, and everywhere else. Skills end up siloed with whoever wrote them, duplicated across teams, with no one accountable for quality. Essentially we're setting up an org where everyone trains and enables themselves with no context.

Skills and context for Claude are just like skills and context for people — the more shared, the faster we can move together. Inspired by Ramp's [Skills Dojo](https://engineering.ramp.com/), Classroom is an open convention any company can adopt.

### What Classroom solves

**A shared marketplace with clear canonical skill ownership** — so we can publish once, access anywhere.

Every skill has an owner — someone accountable for keeping it sharp. Publish once, anyone on the team installs with `claude plugin install <name>@classroom`. No copying files around, no "ask Sarah for her prompt," no three teams maintaining their own version of meeting prep.

**Dynamic pathways, not org charts** — so we can suggest things to leverage for your role, project, or growth areas.

Skills and plugins (a set of skills + connectors) are published by job-to-be-done, not by department, because they should reflect a problem to solve or a workflow. But we still have a gap where we want to push skills to people — like enabling Claude. So this does that. A functional lead bundles ABC for their team; a project lead bundles AYZ for theirs — and the overlap is fine, because it's the same underlying skills. Pathways are just lightweight groupings (a markdown file) that point at shared plugins. You can serve every leader's view of "what my people need" without accidentally shipping the org chart or fragmenting skill ownership.

**Extend without forking** — so I can adapt what I learned in that "training" to my needs and problems.

Users customize a canonical skill by writing a local extension that references the parent — not by copying it. Central updates keep flowing; your customizations ride on top. No drift, no merge conflicts, no "which version is the real one."

**A Guide that meets people where they are** — so you can explore and discover in the flow of work.

Type `/classroom` and it walks you through discovery, installation, and extending existing skills — all conversational, all with confirmation before it does anything. Non-technical users never touch a config file.

## How it works

**Three tiers:**

| Tier | What | Managed by | Example |
|---|---|---|---|
| **Central** | Shared skills organized by problem domain | Maintainers via PR | `ckoglmeier/classroom` (this repo) |
| **Team** | Team-specific extensions and customizations | Team leader | `classroom-extensions-<team>` repo |
| **Personal** | Individual extensions that survive central updates | You | `~/.claude/skills/` local directory |

**Discovery is Claude-native.** You install Classroom, type `/classroom`, tell the Guide your team and role, and it recommends 3–5 skills curated by your team lead via a path file. No web UI, no portal — Claude is the interface.

**Extensions compose, they don't fork.** When you want to customize a central skill, the Guide drafts a local extension that says "load and follow `<parent>`, then also do X, Y, Z." Central updates flow through automatically. See [docs/extending-skills.md](docs/extending-skills.md).

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/ckoglmeier/classroom/main/install.sh | bash
```

**No git required.** macOS and Linux only for now. The installer needs only `curl` and `tar`, which are standard.

This:
1. Downloads a snapshot of the Classroom reference repo to `~/.claude/classroom` (atomic swap — readers never see a half-written cache)
2. Installs the Guide as a personal skill at `~/.claude/skills/classroom`
3. Adds the Classroom marketplace to `~/.claude/settings.json`
4. Installs a `SessionStart` hook that prints a welcome on first run and kicks off a background refresh
5. If OpenAI Codex is detected (`~/.codex/` or `codex` on PATH), mirrors all skills into `~/.codex/skills/` as symlinks so Codex picks them up too

Then open Claude Code (or Codex) and type `/classroom`.

> **Note:** the install script downloads from `$CLASSROOM_REPO` (default: a placeholder GitHub URL). If you're forking this repo for your own company, set `CLASSROOM_REPO` to your fork's URL before running the script.

### Install options

| Env var | Default | Purpose |
|---|---|---|
| `CLASSROOM_REPO` | placeholder GitHub URL | Repo to fetch from. Used to derive the tarball URL. |
| `CLASSROOM_REF` | `main` | Branch *or tag* to install. Set to a tag (e.g. `v0.1.0`) to pin. |
| `CLASSROOM_TARBALL` | derived from REPO+REF | Full tarball URL override for non-GitHub hosts. |
| `CLASSROOM_TARBALL_SHA256` | unset | If set, the downloaded tarball must match this SHA-256. Recommended for secure environments. |
| `CLASSROOM_REFRESH_INTERVAL` | `24` | Hours between background cache refreshes. `0` = every session. `-1` = disable. |

### How Classroom stays current

There are three update channels, by design:

1. **Reference cache** (`~/.claude/classroom/`) — refreshed in the background by `~/.claude/classroom-refresh.sh` on every session start, gated to once per 24h, lock-protected, atomic swap, never blocks. So when central adds a new plugin or updates a path file, you see it within a day with no user action.
2. **Installed plugins** — Claude Code's per-marketplace `autoUpdate` toggle handles updates to plugins you've actually installed via `/classroom install`.
3. **The Guide skill itself** (`~/.claude/skills/classroom/SKILL.md`) — only updates when you opt in. Run `/classroom update` and confirm. The Guide is the one thing actively running on your skill calls, so changing it silently in the background is the wrong default.

Refresh failures are logged to `~/.claude/classroom-refresh.log` and never break a session.

### Contributing

If you're working on Classroom itself (editing the Guide, adding plugins, fixing the installer), use the dev installer instead — it sets up a live `git` checkout at `~/.claude/classroom` that you can `git pull` and edit:

```bash
bash install-dev.sh
```

Run `bash tests/run.sh` from the repo root to validate any change.

## What's in v1

**The Guide skill** — `/classroom`, with conversational subcommands:
- `recommend` — ask team and role, surface curated path
- `install` — browse marketplace, install with confirm-before-action
- `extend` — draft a local extension of a central skill
- `curate-path` — team-lead mode: draft a path file and open a PR
- `owners` — look up the maintainer of any plugin
- `update` — re-run the installer to update the Guide and force a cache refresh
- `schedule` — set up a recurring (daily/weekly) headless skill run via cron or launchd
- `analytics` — summary of which skills you've installed and actually used
- `sync` — mirror Classroom skills to OpenAI Codex so both agents share the same library

**Five seed skills** across four problem-domain plugins:
- `competitive-intelligence/` — `competitive-analysis`
- `customer-research/` — `customer-interview-prep`
- `ops-essentials/` — `weekly-status-update`, `meeting-prep`
- `sales-enablement/` — `stakeholder-followup`

**Two role path files:**
- `paths/sales-ae.md`
- `paths/ops-analyst.md`

**Convention docs:**
- [docs/extending-skills.md](docs/extending-skills.md) — the composition convention
- [docs/path-files.md](docs/path-files.md) — how team leaders curate
- [docs/pr-checklist.md](docs/pr-checklist.md) — central-repo PR review bar
- [docs/npm-packs.md](docs/npm-packs.md) — publishing a plugin to npm
- [docs/telemetry.md](docs/telemetry.md) — local analytics log, opt-out, forwarding
- [docs/scheduled-runs.md](docs/scheduled-runs.md) — headless/recurring skill runs
- [docs/codex-sync.md](docs/codex-sync.md) — syncing Classroom skills to OpenAI Codex

## Repo layout

```
classroom/
├── README.md                     # this file
├── CODEOWNERS                    # per-plugin maintainers (GitHub auto-review)
├── install.sh                    # one-line install bootstrap (no git required)
├── install-dev.sh                # contributor variant (git checkout)
├── classroom-schedule.sh         # scheduler helper (installed to ~/.claude/ by install.sh)
├── classroom-sync-codex.sh       # Codex sync helper (installed to ~/.claude/ by install.sh)
├── guide/SKILL.md                # the Guide skill (copied to ~/.claude/skills/classroom/ on install)
├── .claude-plugin/marketplace.json   # plugin catalog (Claude Code marketplace)
├── plugins/                      # in-tree problem-domain plugins
│   ├── competitive-intelligence/
│   ├── customer-research/
│   ├── ops-essentials/
│   └── sales-enablement/
├── paths/                        # curated bundles by role
│   ├── sales-ae.md
│   └── ops-analyst.md
└── docs/                         # convention specs
    ├── extending-skills.md
    ├── path-files.md
    └── pr-checklist.md
```

## External plugins

Classroom's marketplace supports two kinds of plugin entries in `.claude-plugin/marketplace.json`:

1. **In-tree plugins** (relative `source` like `"./plugins/competitive-intelligence"`) — live in this repo. Code-owned here, validated end-to-end by the test suite, shipped as part of the install tarball.
2. **External plugins** (object `source` with `git-subdir` / `github` / `url` / `npm`) — live in another repo and are cloned by Claude Code at `plugin install` time. Classroom only validates their schema in the manifest; the upstream repo owns the plugin content.

Adding an external plugin is a one-line PR: append an entry to the `plugins` array. The `tests/run.sh` suite validates the source schema (correct type, required fields, ref pinning) offline.

## What's deferred to v1.1+

- **Cowork/Chat sync.** Cross-harness portability so the same skill set works in both Claude Code and claude.ai. High-value for adoption, but defers cleanly. Will require a portability contract (declared `harness:` field, no unguarded Bash) and a sync mechanism.
- **Ambient nudge hook.** "I notice you're doing X — there's a skill for that" surfaced inline during real work.
- **Memory/synthesis pipeline.** Daily summary of recent sessions and connected tools to refresh user context.
- **Scheduled / headless execution.** Long-running and cron-based skill runs.
- **Telemetry.** Which skills get installed, used, abandoned. The signal that tells central maintainers what to invest in.

## Adopting Classroom for your company

1. Fork this repo as `<your-company>-classroom`.
2. Edit `.claude-plugin/marketplace.json`: change `name`, `owner`, and the plugin list.
3. Replace the seed skills in `plugins/` with skills your teams actually use.
4. Replace the path files in `paths/` with role bundles your team leads curate.
5. Update `install.sh` (or set `CLASSROOM_REPO` env var) to point at your fork.
6. Send your team `curl ... | bash`.

## License

MIT. Take it, change it, ship it.

---

*Skills shared like seeds —*
*one prompt blooms across the org,*
*no one works alone.*

— from CK's desk
