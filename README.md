# Classroom

**An open-source convention for distributing skills inside a company, built on Claude Code.**

Classroom is a Ramp-Dojo–style skill marketplace organized by problem domain, with a Guide skill that helps non-technical users discover, install, and extend skills. It's a reference implementation of a convention any company can adopt. 

## Why this exists

Every company now has 50+ AI skills scattered across teams. Three teams independently built "competitive intelligence." Nobody knows what exists. Quality varies wildly. Team-specific plugins create silos and duplication. **Enablement is a distribution failure.**

Classroom is the bet that you can solve distribution with three things:

1. A central git repo that everyone trusts as the source of truth.
2. A convention that lets anyone extend a central skill *without forking it*, so they stay on the update path.
3. A Guide skill that walks non-technical users through discovery, installation, and extension — no terminal required.

This is what Ramp built internally as Glass + Dojo. Classroom is the same idea as an open convention rather than a closed custom harness.

## How it works

**Three tiers:**

| Tier | What | Managed by | Example |
|---|---|---|---|
| **Central** | Shared skills organized by problem domain | Maintainers via PR | `ckoglmeier/classroom` (this repo) |
| **Team** | Team-specific extensions and customizations | Team leader | `dojo-extensions-<team>` repo |
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

Then open Claude Code and type `/classroom`.

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

## Repo layout

```
classroom/
├── README.md                     # this file
├── CODEOWNERS                    # per-plugin maintainers (GitHub auto-review)
├── install.sh                    # one-line install bootstrap (no git required)
├── install-dev.sh                # contributor variant (git checkout)
├── guide/SKILL.md                # the Guide skill (copied to ~/.claude/skills/classroom/ on install)
├── .claude-plugin/marketplace.json   # plugin catalog (Claude Code marketplace)
├── plugins/                      # in-tree problem-domain plugins
│   ├── competitive-intelligence/
│   ├── customer-research/
│   ├── ops-essentials/
│   └── sales-enablement/
│   # (plus external plugins referenced via git-subdir in marketplace.json —
│   #  see "External plugins" below)
├── paths/                        # curated bundles by role
│   ├── sales-ae.md
│   └── ops-analyst.md
└── docs/                         # convention specs
    ├── extending-skills.md
    ├── path-files.md
    └── pr-checklist.md
```

## External plugins

Classroom's marketplace blends two kinds of plugin entries in `.claude-plugin/marketplace.json`:

1. **In-tree plugins** (relative `source` like `"./plugins/competitive-intelligence"`) — live in this repo. Code-owned here, validated end-to-end by the test suite, shipped as part of the install tarball.
2. **External plugins** (object `source` with `git-subdir` / `github` / `url` / `npm`) — live in another repo and are cloned by Claude Code at `/plugin install` time. Classroom only validates their schema in the manifest; the upstream repo owns the plugin content.

Today classroom pulls three generic templates from [`ckoglmeier/skills/templates/`](https://github.com/ckoglmeier/skills/tree/main/templates) via `git-subdir`: `exec-feedback`, `research-assistant`, and `template-strategy-feedback`. They're pinned to `ref: "main"`, so classroom tracks the latest shareable version automatically. The tradeoff is that a breaking change upstream can briefly break classroom installs until the next 24h refresh. If that proves too loose, we'll move to SHA pinning with a bump workflow — see [docs/extending-skills.md](docs/extending-skills.md).

Adding an external plugin is a one-line PR: append an entry to the `plugins` array. The `tests/run.sh` suite validates the source schema (correct type, required fields, ref pinning) offline; a follow-up opt-in layer will sparse-clone and verify the upstream plugin.json matches.

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
