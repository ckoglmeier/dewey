# Classroom

**A plugin marketplace for skills and context — for Claude Code, Cowork, and OpenAI Codex.**

Classroom distributes two things teams share with their agents: **skills** (procedures — how to do something) and **canonical context** (reference content — battlecards, brand voice, ICP definitions, strategy docs). Both are authored once in standard markdown and run in any of the three agents. Cowork shares Claude Code's `~/.claude/` directory — same install, no extra step. When Codex is also installed, Classroom mirrors its skills and context into `~/.codex/` as symlinks — see [docs/codex-sync.md](docs/codex-sync.md).

## Why this exists

Everyone builds their own Claude Code skills right now, on their local machine — and everyone copy-pastes the same battlecards, brand voice notes, and strategy docs into prompts when they need them. The entire system is living in single-player mode: we don't learn, we don't collaborate, and we have constant errors from binaries and content shared in Slack, email, and everywhere else. Skills *and* the reference content they depend on end up siloed with whoever wrote them, duplicated across teams, with no one accountable for quality. Essentially we're setting up an org where everyone trains and enables themselves with no context.

Skills and context for Claude are just like skills and context for people — the more shared, the faster we can move together. Inspired by Ramp's [Skills Dojo](https://engineering.ramp.com/), Classroom is an open convention any company can adopt.

### What Classroom solves

**A shared marketplace with clear canonical ownership** — so we can publish once, access anywhere.

Every skill and every context bundle has an owner — someone accountable for keeping it sharp. Publish once, anyone on the team installs with `claude plugin install <name>@classroom`. No copying files around, no "ask Sarah for her prompt," no three teams maintaining their own version of meeting prep, no four sales reps each pasting a different version of the Acme battlecard into chat.

**Skills and context, not just skills.** Skills tell Claude *how to do something*; context tells it *what your company believes*. A `competitive-analysis` skill can declare `requires-context: competitive-intelligence/positioning` so every brief reflects current company truth, not whatever the model guesses. Updates to the canonical positioning flow through every brief automatically. See [docs/canonical-context.md](docs/canonical-context.md).

**Dynamic pathways, not org charts** — so we can suggest things to leverage for your role, project, or growth areas.

Skills and plugins (a set of skills + connectors + context) are published by job-to-be-done, not by department, because they should reflect a problem to solve or a workflow. But we still have a gap where we want to push the right skills and reference material to people — like enabling Claude. So this does that. A functional lead bundles ABC for their team; a project lead bundles AYZ for theirs — and the overlap is fine, because it's the same underlying plugins. Pathways are just lightweight groupings (a markdown file) that point at shared plugins. You can serve every leader's view of "what my people need" without accidentally shipping the org chart or fragmenting ownership.

**Extend without forking** — so I can adapt what I learned in that "training" to my needs and problems.

Users customize a canonical skill or a canonical context bundle by writing a local extension that references the parent — not by copying it. Central updates keep flowing; your customizations ride on top. No drift, no merge conflicts, no "which version is the real one." The same `extends:` (skills) and `extends-context:` (context) convention works for both.

**A Guide that meets people where they are** — so you can explore and discover in the flow of work.

Type `/classroom` and it walks you through discovery, installation, extending, and proposing changes back — all conversational, all with confirmation before it does anything. Non-technical users never touch a config file.

## How it works

**Three tiers, applied to both skills and context:**

| Tier | What | Managed by | Example |
|---|---|---|---|
| **Central** | Shared skills + canonical context, organized by problem domain | Maintainers via PR | `ckoglmeier/classroom` (this repo) |
| **Team** | Team-specific extensions of skills or context, plus team-only bundles | Team leader | `classroom-extensions-<team>` repo |
| **Personal** | Individual extensions that survive central updates | You | `~/.claude/skills/` local directory |

**Discovery is Claude-native.** You install Classroom, type `/classroom`, tell the Guide your team and role, and it recommends 3–5 plugins curated by your team lead via a path file. No web UI, no portal — Claude is the interface.

**Composition, not forks.** When you want to customize a central skill or context bundle, the Guide drafts a local extension that loads the canonical first and then layers your additions. Central updates flow through automatically. See [docs/extending-skills.md](docs/extending-skills.md) for skills and [docs/canonical-context.md](docs/canonical-context.md) for context.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/ckoglmeier/classroom/main/install.sh | bash
```

**No git required.** macOS and Linux only for now. The installer needs `curl`, `tar`, and `python3`, which are standard on most developer machines.

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
| `CLASSROOM_REF` | `main` | Branch *or tag* to install. Set to a tag (e.g. `v1.1.0`) to pin. |
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

## What's shipped

**The Guide skill** — `/classroom`, conversational subcommands:

| Subcommand | What it does |
|---|---|
| `recommend` | Ask team and role, surface curated path |
| `install` | Browse marketplace, confirm-before-action; resolves `requires-context:` deps and offers to install missing context plugins |
| `extend` | Draft a local extension of a central skill |
| `curate-path` | Team-lead mode: draft a path file and open a PR |
| `owners` | Look up the maintainer of any plugin |
| `update` | Re-run the installer to update the Guide and force a cache refresh |
| `analytics` | Summary of which skills you've installed and actually used |
| `sync` | Mirror Classroom skills + canonical context to OpenAI Codex |
| `propose` | Open a PR against canonical (six sub-flows: new-skill / update / promote, plus parallel new-context / update-context / promote-context-extension) |

**Multi-agent reach.** Same install reaches Claude Code (native), Cowork (shares `~/.claude/`), and standalone Codex (mirrored via symlink). `surfaces:` field in `plugin.json` declares which agents a plugin supports; Guide filters recommendations to the current surface.

**Canonical context.** Plugins ship reference content (battlecards, brand voice, strategy docs) alongside skills. Skills declare `requires-context:` to depend on stable IDs. Layer 14 lint enforces schema, ID resolution, frontmatter/body alignment, surface compatibility, and size limits. See [docs/canonical-context.md](docs/canonical-context.md).

**Extension telemetry.** When users extend canonical skills locally, Classroom captures the extension content (with three-tier opt-out: global / per-plugin / per-skill, plus a body-forwarding gate). This feeds a future hosted aggregator that will surface "12 users added the same step — absorb it into canonical" patterns. See [docs/extension-telemetry.md](docs/extension-telemetry.md).

**Five seed skills** across four problem-domain plugins:
- `competitive-intelligence/` — `competitive-analysis` (with `competitive-intelligence/positioning` canonical context)
- `customer-research/` — `customer-interview-prep`
- `ops-essentials/` — `weekly-status-update`, `meeting-prep`
- `sales-enablement/` — `stakeholder-followup`

**Two role path files:** `paths/sales-ae.md`, `paths/ops-analyst.md`.

**Convention and reference docs** under `docs/`:
- [extending-skills.md](docs/extending-skills.md) — the composition convention for skills
- [canonical-context.md](docs/canonical-context.md) — author's reference for canonical context
- [canonical-context-design.md](docs/canonical-context-design.md) — the design spec
- [path-files.md](docs/path-files.md) — how team leaders curate
- [proposing-changes.md](docs/proposing-changes.md) — the `/classroom propose` flow
- [pr-checklist.md](docs/pr-checklist.md) — central-repo PR review bar
- [surfaces.md](docs/surfaces.md) — surface compatibility model
- [telemetry.md](docs/telemetry.md) — local analytics log, opt-out, forwarding
- [extension-telemetry.md](docs/extension-telemetry.md) — the central learning loop
- [scheduling.md](docs/scheduling.md) — why Classroom doesn't ship a scheduler (use Claude Code's Routines or Cowork's scheduled-tasks instead)
- [codex-sync.md](docs/codex-sync.md) — syncing skills + context to OpenAI Codex
- [npm-packs.md](docs/npm-packs.md) — publishing a plugin to npm
- [roadmap.md](docs/roadmap.md) — what's done, what's partial, what's deferred

## Repo layout

```
classroom/
├── README.md                     # this file
├── CLAUDE.md                     # session notes + open todos for the next session
├── CODEOWNERS                    # per-plugin maintainers (GitHub auto-review)
├── install.sh                    # one-line install bootstrap (no git required)
├── install-dev.sh                # contributor variant (git checkout)
├── classroom-sync-codex.sh       # Codex sync helper (installed to ~/.claude/ by install.sh)
├── classroom-telemetry.sh        # telemetry emit + strip-bodies helper (installed to ~/.claude/ by install.sh)
├── classroom-propose.sh          # propose helper: opens PRs against canonical (installed to ~/.claude/ by install.sh)
├── guide/SKILL.md                # the Guide skill (copied to ~/.claude/skills/classroom/ on install)
├── .claude-plugin/marketplace.json   # plugin catalog (Claude Code marketplace)
├── plugins/                      # in-tree problem-domain plugins
│   ├── competitive-intelligence/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── skills/competitive-analysis/SKILL.md
│   │   └── context/positioning/positioning.md   # canonical context demonstrator
│   ├── customer-research/
│   ├── ops-essentials/
│   └── sales-enablement/
├── paths/                        # curated bundles by role
│   ├── sales-ae.md
│   └── ops-analyst.md
├── docs/                         # convention + reference docs (see "What's shipped")
└── tests/
    ├── run.sh                    # full lint + integration suite (213+ tests across 14 layers)
    └── lib/check_requires_context.py   # Python validator extracted from inline bash
```

## External plugins

Classroom's marketplace supports two kinds of plugin entries in `.claude-plugin/marketplace.json`:

1. **In-tree plugins** (relative `source` like `"./plugins/competitive-intelligence"`) — live in this repo. Code-owned here, validated end-to-end by the test suite, shipped as part of the install tarball.
2. **External plugins** (object `source` with `git-subdir` / `github` / `url` / `npm`) — live in another repo and are cloned by Claude Code at `plugin install` time. Classroom only validates their schema in the manifest; the upstream repo owns the plugin content.

Adding an external plugin is a one-line PR: append an entry to the `plugins` array. The `tests/run.sh` suite validates the source schema (correct type, required fields, ref pinning) offline.

## Roadmap

A full status snapshot — what's done, what's partial (built but not validated end-to-end, like scheduled execution), what's deferred (ambient nudges, memory/synthesis, Chat distribution, broader headless patterns), and the separate **Hosted Classroom** bucket — lives in [docs/roadmap.md](docs/roadmap.md). It's the source of truth for "is X built?"

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
