# Security overview

This document is written for security reviewers evaluating Dewey for adoption. It covers what the installer writes to disk, what runs automatically after install, how releases are pinned and checksummed, what telemetry leaves the machine, and the three-tier opt-out model.

## What install.sh does

`install.sh` is a single self-contained bash script. It requires no root or sudo. Everything it writes is scoped to the current user's home directory.

### Paths written

| Path | What it is |
|---|---|
| `~/.claude/dewey/` | The Dewey reference snapshot (skills, plugins, docs). Replaced atomically on each install or refresh — no half-written state is ever visible. |
| `~/.claude/skills/dewey/SKILL.md` | The Guide skill, copied from the snapshot. This is the `/dewey` slash command. |
| `~/.claude/plugins/known_marketplaces.json` | Plugin registry. The installer adds a `"dewey"` entry pointing at `~/.claude/dewey`. Existing entries are preserved. |
| `~/.claude/settings.json` | Claude Code settings. The installer adds a `SessionStart` hook entry pointing at `~/.claude/dewey-first-run.sh`. Existing settings are merged, not overwritten. |
| `~/.claude/dewey-first-run.sh` | The SessionStart hook (see below). Mode 0755. |
| `~/.claude/dewey-refresh.sh` | The background refresh script (see below). Mode 0755. |
| `~/.claude/dewey-sync-codex.sh` | Optional Codex mirror helper. Mode 0755. |
| `~/.claude/dewey-telemetry.sh` | Local analytics helper. Mode 0755. |
| `~/.claude/dewey-propose.sh` | Skill proposal helper (wraps `gh pr create`). Mode 0755. |
| `~/.claude/dewey-analytics.log` | Local event log (JSONL). Created only if `DEWEY_TELEMETRY != 0`. |
| `~/.claude/dewey-migration.log` | Written only if a prior Classroom install is detected and migrated. |

No files are written outside `~/.claude/` and (if Codex is detected) `~/.codex/skills/`. No system directories are touched.

### Permissions

The installer creates no setuid or setgid files. All scripts are mode 0755. The analytics log is mode 0644 (default umask).

### Network activity during install

One HTTPS request: the tarball download from GitHub (either a release asset URL or the GitHub archive URL for the resolved tag). When installing from a release, a second request fetches the `.sha256` checksum asset to verify the tarball before extraction.

If `DEWEY_TARBALL` is set (e.g. for air-gapped or test installs), no network requests are made.

## What runs automatically after install

### SessionStart hook (`~/.claude/dewey-first-run.sh`)

Runs once per Claude Code session, via the `SessionStart` hook registered in `settings.json`. Does two things:

1. **First-run welcome.** On the very first session after install, prints a one-time welcome message prompting `Type /dewey to get started`. Writes a marker file (`~/.claude/dewey-onboarded`) so this message is never shown again.
2. **Background refresh.** Launches `~/.claude/dewey-refresh.sh` in a fire-and-forget subshell (`( ... & )`). The session is never blocked. If the refresh script is not executable, the launch is silently skipped.

### Background refresh (`~/.claude/dewey-refresh.sh`)

Runs in the background via the hook above. Behavior:

- **Exits immediately** if the 24-hour interval has not elapsed since the last refresh (the interval is configurable via `DEWEY_REFRESH_INTERVAL`; set to `-1` to disable entirely).
- **Lock-protected.** Acquires `~/.claude/dewey-refresh.lock` on entry. Concurrent executions (e.g., two Claude Code windows opening simultaneously) are silently no-oped.
- **Release channel (default).** Queries the GitHub releases API for the latest tag. Fetches the release tarball and its `.sha256` asset. If the checksum file is absent or the download fails, the refresh is **declined** — the existing cache is left untouched. No network failure can break a working install.
- **Main channel** (`DEWEY_REFRESH_CHANNEL=main`). Fetches the `main` branch archive without checksum enforcement. For development and CI use only.
- **Atomic swap.** New content is extracted to a temp directory; the old cache is moved aside atomically before the new one is moved in. If the swap fails, the old cache is restored. The live cache is never in a partially-written state.
- **Always exits 0.** The hook fires at session start; a non-zero exit would abort the session. Every failure path logs to `~/.claude/dewey-refresh.log` and exits 0.

The refresh script is a static file written by `install.sh` at install time. It does not download or execute additional scripts.

## Release pinning and checksum verification

### Default behavior (no env overrides)

1. `install.sh` calls the GitHub releases API (`api.github.com/repos/ckoglmeier/dewey/releases/latest`) to resolve the latest tag.
2. It looks for two release assets: `dewey-<tag>.tar.gz` and `dewey-<tag>.tar.gz.sha256`.
3. If both are found, it downloads the `.sha256` asset and stores the expected hash.
4. The tarball is downloaded. Before extraction, `verify_sha256()` checks the tarball against the expected hash. A mismatch is a hard failure (`die`) — the install aborts and nothing is written to `~/.claude/dewey/`.
5. If the release assets are absent (e.g., the release was created without them), the installer falls back to the GitHub archive URL for the tag and skips checksum verification, warning clearly.
6. If the API call fails entirely (no network, rate-limited), the installer warns and falls back to `main` without verification.

### Explicit overrides

Setting any of these env vars disables release resolution and uses the supplied value directly:

| Env var | Effect |
|---|---|
| `DEWEY_REF=vX.Y.Z` | Pin to a specific tag (uses GitHub archive URL, no release-asset checksum). |
| `DEWEY_TARBALL=<url>` | Use this exact URL. Combine with `DEWEY_TARBALL_SHA256=<hash>` to enforce verification. |
| `DEWEY_USE_INPLACE=1` | Skip all network activity; use whatever is already at `~/.claude/dewey/`. |

### Checksum tool

Verification uses `sha256sum` (GNU coreutils, standard on Linux) with a fallback to `shasum -a 256` (Perl, standard on macOS). If neither is available, the install fails rather than proceeding unverified.

### Publishing checksums

Checksums are published as GitHub release assets (`.sha256` files alongside the tarball). The asset URL is resolved at install time from the releases API response — it is not hardcoded. This means the checksum source of truth is the same GitHub release that hosts the tarball.

## Telemetry

Dewey logs usage events locally. No data leaves the machine by default.

### What is logged

Events are appended to `~/.claude/dewey-analytics.log` as JSONL. The events are:

| Event | When |
|---|---|
| `first_run` | First Claude Code session after install |
| `refresh_success` / `refresh_failure` | Background cache refresh outcome |
| `guide_recommend` | Guide completed a path recommendation |
| `skill_install` | User confirmed installing a plugin |
| `skill_invoke` | Guide routed to a specific skill |
| `extension_created` | User created a local skill extension via `/dewey extend` |

Fields carried: timestamps, skill/plugin names, path identifiers. No personally identifiable information is captured by default. Note that once forwarding is enabled, the stable `install_id` (below) joined with skill names and timestamps makes the stream *pseudonymous*, not anonymous — in a small org, usage patterns can be re-identifying. Forwarding is off by default and license-gated.

### Three-tier opt-out

Privacy is enforced at three layers, evaluated in order:

1. **Global opt-out** (`DEWEY_TELEMETRY=0`): set in your shell profile to suppress all event logging. The analytics log file is not created at all. Nothing is ever written.

2. **Per-plugin / per-skill opt-out** (`telemetry: false` in `plugin.json` or SKILL.md frontmatter): skill authors can mark individual skills or entire plugins as off-limits. Events about those scopes are not written even if global telemetry is on. Intended for HR, legal, medical-adjacent, or otherwise sensitive workflows.

3. **Body-forwarding opt-in** (`DEWEY_TELEMETRY_FORWARD_BODIES=1`): the `extension_created` event carries two prose fields — `additions` (the user-authored extension body) and `user_intent` (their one-line description). These fields are logged locally but stripped before any forwarding. They only leave the machine if you explicitly set this env var.

### Pseudonymous install ID

Every install generates a pseudonymous install ID: 16 lowercase hex characters produced by a CSPRNG (`python3 -c "import secrets; print(secrets.token_hex(8))"`). The ID is stored in `~/.claude/dewey-install-id` (mode 0600) and included as `install_id` on every emitted telemetry event.

**What it is NOT**: the ID is not derived from the hostname, username, MAC address, or any other machine-identifying information. It is purely random. If you delete `~/.claude/dewey-install-id` and reinstall, a completely different ID is generated — the new ID cannot be linked to the old one.

**Opt-out behaviour**: all three opt-out tiers (`DEWEY_TELEMETRY=0`, per-plugin `telemetry: false`, per-skill `telemetry: false`) suppress the entire event. The install ID never travels alone — it is only present when the rest of the event is permitted to be emitted. Hand-built environments that lack the file simply emit no `install_id` field.

**Purpose**: the hosted aggregator uses distinct `install_id` counts per org per billing period for seat measurement, enabling per-seat recurring pricing without collecting names, emails, hostnames, or usernames. The ID is pseudonymous rather than anonymous: it is stable per install, so forwarded events from one machine are linkable to each other (that linkage is what makes seat counting possible).

### Forwarding to a central endpoint

Forwarding is **off by default** and requires explicit configuration:

```bash
export DEWEY_TELEMETRY_ENDPOINT=https://your-internal-analytics.example.com/dewey
```

When set, the Guide POSTs the local log to this endpoint at session end, then truncates the local log. The forwarder runs `~/.claude/dewey-telemetry.sh strip-bodies` before sending — this removes `additions` and `user_intent` from `extension_created` events unless `DEWEY_TELEMETRY_FORWARD_BODIES=1` is also set.

There is no vendor SDK. The endpoint is any HTTP service that accepts a JSONL POST. Dewey does not contact any Anthropic-operated endpoint.

## No license key required for local function

Dewey's local function (installer, Guide skill, plugins, lint, refresh) does not require a license key. There is no license check, no call-home on install, and no degraded mode for unlicensed installs. A missing or invalid license key never breaks local Dewey.

License keys are reserved for future hosted features (telemetry aggregation, digest emails). If a key is present, it is stored at `~/.claude/dewey-license` (mode 0600) and sent as an auth bearer when forwarding telemetry. It is never logged or echoed. The full wire contract (key format, endpoint semantics, batch limits, client requirements) is specified in [`docs/hosted-api.md`](hosted-api.md).
