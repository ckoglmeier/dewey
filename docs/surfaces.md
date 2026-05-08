# Surface compatibility

Dewey skills can run in four "surfaces" — the different ways a user invokes Claude. Each surface exposes a different toolset, so a skill that works in one may break in another.

| Surface | Where | Tools available |
|---|---|---|
| `claude-code` | Claude Code CLI | Full: Bash, Read, Edit, Write, Glob, Grep, MCP |
| `cowork` | Claude desktop app (Cowork tab) | Most of Claude Code's tools, with user-approval gates on Bash |
| `codex` | OpenAI Codex CLI | SKILL.md format only — no Anthropic-specific tooling |
| `chat` | claude.ai | No filesystem, no Bash, no local processes |

## Declaring surfaces

Every plugin's `plugin.json` declares which surfaces its skills are designed for:

```json
{
  "name": "competitive-intelligence",
  "surfaces": ["claude-code", "cowork", "codex", "chat"]
}
```

If `surfaces` is omitted, Dewey treats it as `["claude-code"]` — the safest default, since Claude Code is the original target.

## Authoring rules

- **Pure text-generation skills** (drafting, analyzing, summarizing) usually support all four surfaces.
- **Skills that use `Bash` in `allowed-tools`** must drop `chat` from `surfaces` — Chat has no shell.
- **Skills that read or write local files** must drop `chat` — Chat has no filesystem.
- **Skills that depend on a specific MCP server** should test it works in each declared surface; MCP support varies.

## Lint check

`tests/run.sh` enforces one rule today: a SKILL.md whose plugin claims `chat` support must not declare `Bash(...)` in its `allowed-tools` frontmatter. Mismatch fails the test.

More rules will be added as we learn the failure modes.

## How the Guide uses this

When you run `/dewey recommend` or `/dewey install`, the Guide:

1. Detects which surface it's running in (env var `DEWEY_SURFACE`, falling back to asking)
2. Filters the marketplace to plugins whose `surfaces` includes the current surface
3. Hides incompatible skills from your recommendations

So a Cowork user never gets a `chat`-only skill suggested; a Chat user never gets a Bash-heavy one.

## Why not skill-level surfaces?

Skills are bundled into plugins, and a plugin is the unit of install. Mixed-compatibility plugins force the user to reason about each skill individually. The trade-off: if one skill in a plugin needs Bash, the whole plugin drops `chat`. Fine — split the plugin.
