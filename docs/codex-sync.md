# Dewey + OpenAI Codex sync

Dewey works with both Claude Code and OpenAI Codex. SKILL.md format is identical between the two agents — the same skill files work in both without modification.

When you have both agents installed, Dewey mirrors its skills to `~/.codex/skills/` as symlinks so Codex picks them up automatically.

## How it works

| | Claude Code | OpenAI Codex |
|---|---|---|
| **Skill directory** | `~/.claude/skills/` | `~/.codex/skills/` |
| **Plugin cache** | `~/.claude/plugins/cache/` | (not applicable) |
| **Reference cache** | `~/.claude/dewey/` | synced from Dewey cache |
| **Skill format** | SKILL.md | SKILL.md (identical) |
| **Project context** | CLAUDE.md | AGENTS.md |

Dewey uses **symlinks** rather than copies, so when the Dewey cache refreshes (every 24h in the background), the Codex skills update automatically too.

## Setup

The installer handles this automatically. If Codex is installed before you run Dewey's installer, you're done:

```bash
curl -fsSL https://raw.githubusercontent.com/ckoglmeier/dewey/main/install.sh | bash
```

If you install Codex after Dewey is already set up, run:

```bash
/dewey sync force
```

Or re-run the installer:

```bash
/dewey update
```

## Env vars

| Var | Default | Effect |
|---|---|---|
| `DEWEY_SYNC_CODEX` | `auto` | `auto` = sync if Codex detected; `1` = always sync; `0` = never sync |
| `CODEX_HOME` | `~/.codex` | Where Codex stores config/skills |

## Manual sync

```bash
# Check current sync state
bash ~/.claude/dewey-sync-codex.sh --status

# Force a full re-sync
bash ~/.claude/dewey-sync-codex.sh

# Remove all Dewey symlinks from Codex (leaves non-Dewey files alone)
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

## AGENTS.md for project context

Codex reads `AGENTS.md` from your repo root as project-level context. Generate one that lists your installed Dewey skills:

```bash
bash ~/.claude/dewey-sync-codex.sh --agents-md .
```

Or: `/dewey sync agents-md`

The generated file looks like:

```markdown
# Dewey Skills

This project has access to skills from the Dewey marketplace.
The following skills are available in your Codex environment:

- `/meeting-prep` — Prepare for meetings...
- `/competitive-analysis` — Analyze competitors...
...
```

Commit it to your repo so Codex sees the skill list in every session.

## What gets synced

Everything in the Dewey reference cache is mirrored:
- All skills from all installed plugins (`plugins/*/skills/*/SKILL.md`)
- The Guide skill itself (`guide/SKILL.md` → `~/.codex/skills/dewey/SKILL.md`)
- All canonical context directories (`plugins/*/context/`) → `~/.codex/context/<plugin>/`

Skills and context that exist in `~/.codex/skills/` or `~/.codex/context/` but are not from Dewey are **not touched**.

### Why a separate `~/.codex/context/` directory?

Dewey skills declare `requires-context:` for canonical content (see [canonical-context.md](canonical-context.md)). On Claude Code and Cowork, those files live at `~/.claude/dewey/plugins/<plugin>/context/...`. Standalone Codex doesn't share `~/.claude/`, so the sync mirrors each plugin's `context/` directory to `~/.codex/context/<plugin>/`. Skills authored for Dewey should reference both possible paths in their "First, load:" step so they work in either environment.

## Refresh cadence

The Dewey background refresh (`~/.claude/dewey-refresh.sh`) runs the Codex sync automatically on each successful cache update, so new skills added to Dewey appear in Codex within 24h with no user action.

## Troubleshooting

**"Codex not detected"**
The sync checks for `~/.codex/` or `codex` on PATH. Make sure Codex is installed: [github.com/openai/codex](https://github.com/openai/codex)

**Skill shows up in status but Codex doesn't offer it**
Codex reads skills at session start. Close and reopen Codex after syncing.

**Symlink is broken**
Run `bash ~/.claude/dewey-sync-codex.sh` to re-sync. This happens if the Dewey cache was cleared and re-downloaded (the symlink target changed). The refresh script handles this automatically on next background refresh.

**Want copies instead of symlinks**
The sync uses symlinks by design so refreshes propagate automatically. If you need copies (e.g. for a shared system where home dirs differ), run after sync:
```bash
for link in ~/.codex/skills/*/SKILL.md; do
  [[ -L "$link" ]] && cp "$(readlink "$link")" "${link}.copy" && mv "${link}.copy" "$link"
done
```
