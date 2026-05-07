# Roadmap

A working snapshot of what's done, what's partial, and what's deferred. Updated as features land.

## Done

### Distribution
- One-line install via `curl | bash` (tarball, no git required)
- Atomic-swap reference cache with 24h background refresh
- `SessionStart` hook for first-run welcome and refresh kickoff
- Marketplace registration via `~/.claude/plugins/known_marketplaces.json`
- External plugin support in `marketplace.json` (object `source` shapes — `git-subdir`, `github`, `url`, `npm`) — *see Partial below for current Claude Code validator caveat*

### Multi-agent reach
- **Claude Code**: native (the original target)
- **Cowork**: shares `~/.claude/` with Claude Code — zero extra work, automatic
- **OpenAI Codex**: skills + canonical context mirrored as symlinks to `~/.codex/skills/` and `~/.codex/context/<plugin>/` via `classroom-sync-codex.sh`
- `surfaces:` field in `plugin.json` declares which agents a plugin supports; Guide filters recommendations to the current surface

### The Guide skill (`/classroom`)
- `recommend` — path-driven role recommendation
- `install` — confirm-before-action installs, with `requires-context:` dependency resolution and offer-to-install for missing context plugins
- `extend` — local skill extensions via the composition convention
- `curate-path` — team-lead path-file authoring with PR drafting
- `owners` — look up plugin maintainer
- `update` — re-run installer to refresh Guide and cache
- `schedule` — set up recurring skill runs (see Partial)
- `analytics` — local usage summary
- `sync` — Codex sync status / force / agents-md generation
- `propose` — open PRs against canonical (six sub-flows: new-skill / update / promote, plus parallel new-context / update-context / promote-context-extension)

### Canonical context (v1)
- `context: []` array in `plugin.json` with stable `<plugin>/<bundle>` IDs
- `requires-context:` declarations in skill frontmatter
- `extends-context:` for layered extensions (mirrors the skill extension convention)
- Layer 14 lint: schema validation, ID resolution, frontmatter/body drift detection, surface compatibility, size limits (20KB/100KB per file; 80KB/300KB total) with `allow-large-context: true` override
- Demonstrator content seeded (`competitive-intelligence/positioning`)
- Codex sync mirrors `context/` alongside `skills/`
- Convention-based loading via explicit Read in skill bodies (no runtime mediator)

### Telemetry — capture and forwarding
- Local JSONL log at `~/.claude/classroom-analytics.log`
- Events: `first_run`, `refresh_success`, `refresh_failure`, `guide_recommend`, `skill_install`, `skill_invoke`, `extension_created` (enriched with parent_plugin, additions, tools_added, user_intent), `schedule_created`
- Three-tier opt-out: `CLASSROOM_TELEMETRY=0` global, plugin-level `telemetry: false`, skill-level `telemetry: false`
- Body-forwarding gate: `CLASSROOM_TELEMETRY_FORWARD_BODIES=1` opt-in to forward `additions` and `user_intent`; default-strip via `classroom-telemetry.sh strip-bodies`
- `CLASSROOM_TELEMETRY_ENDPOINT` contract for forwarding (no implementation; documented for future hosted aggregator to consume)

### PR authoring
- `classroom-propose.sh`: clone-or-refresh working dir, branch, lint via `tests/run.sh`, push, open PR via `gh`. Auto-forks if no write access.
- Path-traversal guards on `--target-path`
- `--check`, `--prepare`, `--dry-run` modes

### Test suite
- 213+ tests across 14 layers covering: marketplace schema, install pipeline (no-git tarball path with checksum), refresh script semantics, ownership, plugin packaging, surfaces, schedule helper, analytics log, Codex sync (skills + context), extension telemetry (helper + opt-out gates + body-strip), propose helper, canonical context (schema + lint + size + surface compat)

### Convention docs
All under `docs/`: `extending-skills.md`, `path-files.md`, `pr-checklist.md`, `npm-packs.md`, `telemetry.md`, `extension-telemetry.md`, `scheduled-runs.md`, `codex-sync.md`, `surfaces.md`, `proposing-changes.md`, `canonical-context.md`, `canonical-context-design.md`, `roadmap.md` (this file).

## Partial

### Scheduled execution
- **Done**: `classroom-schedule.sh` writes a launchd plist (macOS) or crontab line (Linux) wrapping `claude --print "/<skill>"`, validates inputs, sets up logging at `~/classroom-logs/<skill>.log`. Guide §7 collects parameters and invokes the helper. Layer 8 covers dry-run, syntax, helper install.
- **Not validated**: end-to-end. No test or manual run has confirmed that a real scheduled job actually fires at the right time, has working `ANTHROPIC_API_KEY` in scope, and produces a usable log entry. Treat as best-effort until verified live.

### External plugin references
- **Done**: schema validation for `git-subdir`, `github`, `url`, `npm` source types in `marketplace.json`. Layer 3b enforces the schema offline.
- **Blocked on Claude Code**: three external `git-subdir` entries (`exec-feedback`, `research-assistant`, `template-strategy-feedback`) were temporarily removed because Claude Code's `marketplace add` validator currently rejects `git-subdir` sources at registration time, even though they work at runtime. Re-add once the validator is fixed.

### Cowork compatibility
- **Done**: Cowork shares `~/.claude/` with Claude Code, so installs propagate automatically. Verified by inspecting a live Cowork install (`~/Library/Application Support/Claude/claude-code/...` bundles a Claude Code runtime).
- **Open**: Cowork's plugin marketplace UI may surface things differently from Claude Code; we haven't audited that experience.

## Deferred

### Headless execution beyond cron
- **Webhook / event-triggered runs**: HTTP POST → run skill X. No infrastructure.
- **Long-running agentic loops**: skill runs, evaluates output, decides next step, runs another. No primitive for this in shell.
- **Output sinks beyond log files**: post to Slack, file a Linear issue, write to a dashboard. Skills can do this individually but there's no shared sink convention.
- **Schedule observability**: a `/classroom schedule status` command that shows what's scheduled, last run, last failure. Today the user has to grep launchctl/crontab + log files.

### Ambient nudge hook
"I notice you're doing X — there's a skill for that" surfaced inline during real work. Would need a hook that watches user prompts pre-skill-routing and inserts suggestions.

### Memory / synthesis pipeline
Daily summary of recent sessions and connected tools to refresh user context. Currently captured manually via memory skills, not a Classroom convention.

### Chat (claude.ai) distribution
Cowork shares Claude Code's filesystem; Codex is mirrored via symlink; Chat is hosted and has no local skill directory. To get Classroom skills into Chat:
- **Manual upload + bundle export**: a `classroom-export-chat.sh` that produces an upload bundle. Documented click path. No native distribution.
- **API push**: only if Anthropic exposes a Skills API for claude.ai accounts. Not yet investigated.
- **Org-managed marketplace** for Team/Enterprise plans: lands automatically when a company adopts Classroom in the admin marketplace, but that's an Anthropic-side feature not a Classroom one.

## Hosted Classroom bucket

A separate hosted product layer that consumes the local data pipe. Not part of this repo's roadmap directly, but the local side is built to feed it.

- **Aggregator + analyzer** for forwarded telemetry. Receives `extension_created` events from N users, identifies common patterns ("12 users added a Slack lookup to `weekly-status-update`"), proposes canonical updates back to maintainers.
- **MCP for native push**: an MCP server exposing `propose_skill`, `propose_skill_update`, `propose_context`, etc. Native conversational authoring from Code or Codex without `gh` plumbing.
- **Publisher mode**: an embedded Claude API conversation tailored for skill/context owners (separate from the consumer Guide). Review queue, see usage data, manage versions, see extension patterns, accept/reject proposals.
- **Marketplace UI**: web UI for browsing skills, context, paths. Especially useful for non-technical authors who don't want to clone the repo.
- **Staged rollouts**: canary a new canonical to N% of installs before global. Today every refresh swaps the cache for everyone within 24h.
- **Multi-owner governance**: required reviewers from multiple CODEOWNERS for high-impact changes; deprecation flows; version diffs across deployed users.
- **Chat distribution** via the same backend.

## How decisions land here

- A new feature in the repo bumps an item from **Deferred** → **Done** (or **Partial**) and adds a section under **Done** describing what's actually shipped.
- Untested-live items live in **Partial** until verified — don't claim **Done** based on unit tests alone for anything that crosses a network or scheduler boundary.
- New ideas that come up in design discussions go in **Deferred** with a one-line problem statement, not a half-spec.
- Hosted-product ideas go in the **Hosted Classroom bucket** and don't drive this repo's roadmap unless they need a hook on the local side.
