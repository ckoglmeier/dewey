# Dewey + OpenAI Codex

Dewey works with both Claude Code and OpenAI Codex. Since Dewey 2.3 the Codex integration uses Codex's **native plugin marketplace** (Codex 0.149+): Codex reads Dewey's manifests directly, so the same plugins install in both agents without translation.

## How it works

| | Claude Code | OpenAI Codex |
|---|---|---|
| **Marketplace manifest** | `.claude-plugin/marketplace.json` | `.agents/plugins/marketplace.json` (generated from the Claude one; Codex also accepts the Claude manifest as a legacy-compatible fallback) |
| **Plugin manifest** | `.claude-plugin/plugin.json` | same file (Codex reads it) |
| **Install** | `claude plugin install <plugin>@dewey` | `codex plugin add <plugin>@dewey` |
| **Where installed plugins live** | in place, from `~/.claude/dewey/plugins/` | copied to `${CODEX_HOME:-~/.codex}/plugins/cache/dewey/<plugin>/<version>/` |
| **Skill format** | `SKILL.md` (Agent Skills core + Claude extras) | `SKILL.md` (Agent Skills core; Claude-only keys such as `allowed-tools`, `argument-hint`, `user-invocable` are silently ignored) |
| **Invoke a skill** | `/skill-name` | `$skill-name` — type `$` and pick from the list. `/` is reserved for Codex's own commands |
| **User skills dir** | `~/.claude/skills/` | `~/.agents/skills/` (`~/.codex/skills/` is deprecated but still scanned) |
| **Project context** | `CLAUDE.md` | `AGENTS.md` (no skill list needed — Codex builds its own catalog) |
| **Scheduler** | Routines | Automations (`~/.codex/automations/`) |

The Guide is not part of any plugin, so the sync links it as a directory symlink at `~/.agents/skills/dewey` — invoke it in Codex as `$dewey`.

## Setup

The installer handles this automatically. If Codex is installed before you run Dewey's installer, you're done:

```bash
curl -fsSL https://raw.githubusercontent.com/ckoglmeier/dewey/main/install.sh | bash
```

If you install Codex after Dewey is already set up, run:

```
/dewey sync force
```

Or re-run the installer with `/dewey update`. Codex detects new plugins and skills automatically; no restart is needed.

## What the sync does

`~/.claude/dewey-sync-codex.sh` picks a mode:

- **plugin** (default when `codex plugin` exists): registers `~/.claude/dewey` as a Codex marketplace named after the Dewey manifest (`dewey`, or your fork's name) and runs `codex plugin add <plugin>@dewey` for every in-tree plugin. Re-running it re-copies each plugin from the cache, which is how Dewey refreshes reach Codex: the background refresh script runs the sync after every successful cache update.
- **symlink** (fallback for Codex builds without `codex plugin`): symlinks every skill *directory* into `~/.agents/skills/<skill>`. Codex follows symlinked skill directories; it never discovers symlinked `SKILL.md` *files*, which is why Dewey ≤ 2.2's per-file mirror silently stopped working.

Both modes remove leftovers from Dewey ≤ 2.2: `~/.codex/skills/<name>/SKILL.md` file symlinks and `~/.codex/context/<plugin>` mirrors (`~/.codex/context/` is not a Codex concept). Anything in Codex that Dewey didn't create is left alone.

## Env vars

| Var | Default | Effect |
|---|---|---|
| `DEWEY_SYNC_CODEX` | `auto` | Installer: `auto` = sync if Codex detected; `1` = always; `0` = never |
| `DEWEY_CODEX_MODE` | `auto` | `auto` / `plugin` / `symlink` (see above) |
| `CODEX_HOME` | `~/.codex` | Codex config dir (Codex honours the same variable) |
| `DEWEY_AGENTS_SKILLS_DIR` | `~/.agents/skills` | Where skill / Guide symlinks go |

## Manual sync

```bash
# Check current sync state
bash ~/.claude/dewey-sync-codex.sh --status

# Sync now (register marketplace + install / refresh plugins)
bash ~/.claude/dewey-sync-codex.sh

# Remove everything Dewey put in Codex (plugins, marketplace, symlinks)
bash ~/.claude/dewey-sync-codex.sh --remove

# Dry-run: show what would change
bash ~/.claude/dewey-sync-codex.sh --dry-run
```

Or from within Claude Code:

```
/dewey sync
/dewey sync force
/dewey sync status
```

You can also skip Dewey's helper entirely and use Codex directly:

```bash
codex plugin marketplace add ~/.claude/dewey      # or: codex plugin marketplace add ckoglmeier/dewey
codex plugin add ops-essentials@dewey
codex plugin list
```

## Canonical context in Codex

Skills that declare `requires-context:` list two places to read the bundle from: the Dewey cache (`~/.claude/dewey/plugins/<plugin>/context/...`, present on any machine with Dewey installed) and a path relative to the plugin root (`context/<bundle>/context.md`), which works inside Codex's plugin cache because `codex plugin add` copies the whole plugin, `context/` included. No separate context mirror is needed.

## Keeping the manifests in sync

`.agents/plugins/marketplace.json` is generated. After editing `.claude-plugin/marketplace.json`:

```bash
python3 scripts/sync-codex-marketplace.py
```

Layer 3 of the test suite fails if the two drift.

## Troubleshooting

**"Codex not detected"**
The sync checks for `${CODEX_HOME:-~/.codex}` or `codex` on PATH. Install the Codex CLI first: https://github.com/openai/codex (the Codex desktop app merged into the ChatGPT app in July 2026; the CLI is a separate install).

**A skill doesn't show up in Codex**
Type `$` — skills are listed there, not under `/`. Run `bash ~/.claude/dewey-sync-codex.sh --status` to see what's installed. If you are on the symlink fallback, make sure the entry under `~/.agents/skills/` is a symlinked *directory*, not a symlinked file.

**Plugin content is stale in Codex**
Codex copies plugins into its cache. Run `/dewey sync force` (or wait for the next background refresh, which re-syncs automatically).

**Testing the plugin mode**
`DEWEY_TEST_CODEX_PLUGIN=1 bash tests/run.sh` runs the live plugin-mode tests against a sandboxed `CODEX_HOME` on a machine with `codex` installed. The default suite never calls the real CLI.
