# Dewey — Implementation Plan

> **For reviewers:** This document covers two phases. **Part 1 (v1)** is the architecture and spec for what has already been implemented and shipped — included for full context so a new engineer can understand the system before reviewing the delta. **Part 2 (v1.0.1)**, at the bottom, is the proposed next change set: drop the git dependency, add a refresh path, add an ownership layer. Read top-to-bottom, but the actionable work being proposed is in Part 2.
>
> Repo root: `/Users/ck/skill-marketplace`. Run `bash tests/run.sh` from there to validate any change.

---

# Part 1 — v1 (shipped): Architecture Sketch + Spec

## Context

Dewey is a skill/context marketplace convention for businesses, aimed at non-technical users — the same wedge Ramp hit with Dojo (the skills marketplace inside their custom harness "Glass"). The strategic bet, from the Ramp post: *"We don't believe in lowering the ceiling. We believe in raising the floor."* One person's breakthrough should become everyone's baseline, and the product itself should be the enablement.

**Distribution model: open-source convention.** Not a SaaS, not internal-only. Dewey is a public spec + reference implementation any company can adopt. No hosted central repo, no Dewey auth — each adopting company runs its own central git repo following the convention. The Guide skill and the install template are the actual "product."

**v1 scope: Claude Code only.** Cross-harness portability (Cowork/Chat sync) is valuable for adoption but is deferred to v1.1+ so it doesn't derail initial progress. v1 is built natively on Claude Code's plugin marketplace primitive.

The one-page spec commits to three opinionated choices:

1. **Claude-native, no custom harness.** Ramp built Glass; we're betting Claude Code *is* the interface. Discovery happens via `/plugin`, an Install Guide skill (the "Sensei"), and eventually MCP tools.
2. **Three-tier marketplace** — Central (immutable, PR-managed) / Team (extension repos) / Personal (local). Skills are organized by **problem domain, not team**.
3. **Extensions compose, they don't fork.** A local extension is a standalone skill that says *"load and follow `competitive-analysis`, then also do X, Y, Z."* Central updates never touch the extension — the user stays on the update path.

The hard part isn't the marketplace plumbing (Claude Code already has it). The hard part is the **non-technical onboarding loop**: getting someone from "new laptop" → "I have the right 5 skills installed and I'm using them" without ever touching a terminal command.

---

## Architecture Sketch

### Layer 1 — Substrate (already exists in Claude Code)

| Concern | Mechanism | Net-new? |
|---|---|---|
| Skill format | Claude Code skills (markdown + frontmatter) | No |
| Distribution | Plugin marketplaces (`marketplace.json` in a git repo) | No |
| Install/update | `/plugin` command, auto-update toggle per marketplace | No |
| Local overrides | `~/.claude/skills/` and project-level `.claude/` | No |
| Tool access | MCP servers declared per plugin | No |
| Hooks / automation | `settings.json` hooks | No |

**Implication:** Don't build a new marketplace runtime. Lean on Claude Code's plugin marketplace as the substrate. Dewey v1 is a *convention layer* + a *Guide skill* + an *install template* on top of it. Net-new code is small.

### Layer 2 — Three repos, one convention

```
company-dewey/                  # Tier 1: Central (immutable to users)
├── .claude-plugin/marketplace.json
├── plugins/
│   ├── competitive-intelligence/
│   ├── customer-research/
│   └── ...                         # organized by problem domain
└── paths/                          # curated bundles (see Layer 3)
    ├── sales-ae.md
    └── ops-analyst.md

dewey-extensions-[team_name]/        # Tier 2: Team
├── .claude-plugin/marketplace.json
└── skills/
    └── sales-gong-deepdive/        # extends competitive-analysis
        └── SKILL.md                # composes parent by reference

~/dewey-extensions-[user]/           # Tier 3: Personal (local only)
└── skills/
    └── my-weekly-review/
```

The "extension by composition" convention is just a SKILL.md template:

```markdown
---
name: sales-gong-deepdive
extends: competitive-analysis     # convention, not enforced
---
First, load and follow the `competitive-analysis` skill.
Then additionally:
- Pull the last 5 Gong calls for {{account}}
- Cross-reference with Salesforce opportunity stage
- Output as a battlecard in our team template
```

No new runtime needed. Claude reads `extends:`, loads the parent skill, then layers the child's instructions.

### Layer 3 — The Guide skill (the Sensei)

The single most important piece of net-new work. One skill, four jobs, **always confirms before taking action**:

1. **Recommend** — Asks team and role → reads `paths/[role].md` → recommends 3–5 skills with one-line "why this matters."
2. **Install** — Proposes the install plan as a numbered list, asks for approval, then runs `claude plugin install` for each.
3. **Extend** — Reads parent skill, asks "what would you change?", drafts the local extension SKILL.md, shows it for confirmation, writes to `~/dewey-extensions-[user]/`.
4. **Curate (team-leader mode)** — Drafts `paths/[role].md`, opens a PR.

The Guide is itself a skill, auto-installed by `install.sh` to `~/.claude/skills/dewey/`.

### Layer 4 — Update flow (v1)

- Central repo updates → `install.sh` re-run pulls latest via `git pull`.
- Per-marketplace `autoUpdate` toggle on installed plugins (existing Claude Code primitive).
- Personal extensions live *outside* the marketplace cache — central updates physically can't touch them.

### Layer 5 — Onboarding (the Ramp lesson)

Ramp's #1 finding: *"the people who got the most value weren't the ones who attended training. They were the ones who installed a skill on day one and immediately got a result."*

Three steps:
1. **One-line install** — `curl ... | bash` configures `~/.claude/settings.json`, registers the marketplace, drops the Guide skill.
2. **First-run prompt** — `SessionStart` hook welcomes the user and tells them to type `/dewey`.
3. **Ambient discovery** *(future)* — When Claude detects a task that matches an uninstalled skill, surface "there's a skill for this — install?" inline.

---

## v1 — What was built

| # | Artifact | Path |
|---|---|---|
| 1 | Reference marketplace catalog | `.claude-plugin/marketplace.json` |
| 2 | The Guide skill | `guide/SKILL.md` |
| 3 | Four seed plugins (competitive-intelligence, customer-research, ops-essentials, sales-enablement) | `plugins/*/` |
| 4 | Two role path files | `paths/sales-ae.md`, `paths/ops-analyst.md` |
| 5 | One-line install script | `install.sh` |
| 6 | First-run SessionStart hook (written by install.sh) | `~/.claude/dewey-first-run.sh` |
| 7 | Convention docs | `docs/extending-skills.md`, `docs/path-files.md`, `docs/pr-checklist.md` |
| 8 | 84-test suite (4 layers: structural, frontmatter, cross-ref, sandbox install) | `tests/run.sh` |

## v1 verification

End-to-end test of the MVP loop on a fresh laptop:

1. Run `install.sh` → `~/.claude/settings.json` has the marketplace and the Guide is installed.
2. Open Claude Code → SessionStart hook fires → user types `/dewey` → Guide asks team/role → recommends 3 skills.
3. User says "yes install" → Guide runs install for each → all three appear in `/plugin` list.
4. User runs one recommended skill on real data → result in <2 minutes.
5. `/dewey extend [skill_name]` → Guide generates a local extension → parent still updates from central without touching the extension.
6. Team lead runs `/dewey curate-path` → PR opens against central → after merge, new team members get that path.

## Decisions locked for v1

- **Open-source convention** model (not SaaS, not internal-only).
- **Claude Code only.** Cowork sync deferred to v1.1+.
- **Single-maintainer Guide repo.** Guide is the most valuable artifact; single owner controls quality through v1.
- **Always-confirm Guide.** Proposes, user approves each action.

---

# Part 2 — v1.0.1 (proposed): Drop the git dependency, add refresh + ownership

> **Principal review incorporated (revision 2).** All five must-fixes folded in inline below: (1) optional checksum verification via `DEWEY_TARBALL_SHA256`, (2) destructive-path guard before any `rm -rf`, (3) atomic dir swap to eliminate the read-during-write race with `refresh.sh`, (4) lock file in `refresh.sh` to prevent concurrent execution, (5) portable `( ... & )` subshell instead of `& disown`. Also incorporated: tightened dev-checkout detection (now requires `.git/`), local-edit overwrite warning, refresh-log timestamp for observability. Out-of-scope items from the review (full versioning, schema validation, advanced observability) remain out of scope.

## Context

v1 ships with `install.sh` requiring `git` on the user's machine and cloning the central repo to `~/.claude/dewey/`. Two problems for the non-technical target user:

1. **`git` isn't always there.** Many non-engineer laptops don't have git, or have a stale Xcode CLT prompt that breaks the curl|bash flow on first ever run. The Ramp finding is "first-run wow within 60 seconds" — a CLT installer popup destroys that.
2. **`git clone` is the wrong primitive for a snapshot consumer.** The user never pulls, branches, or commits inside `~/.claude/dewey/`. They just need the files. A tarball download is exactly that, with no preflight dependency.

The fix is small: replace `git clone` / `git pull` with a tarball fetch (`curl ... | tar -xz`). The Guide skill, the on-disk layout, paths/, and the existing "exists but not git" dev branch stay the same. Contributors who want a live git checkout move to `install-dev.sh`. We also add a periodic refresh path and an ownership layer.

## Approach

No Guide allowed-tools changes. No settings.json schema changes. No new runtime dependencies on the Guide.

### File-by-file

**1. `install.sh` — replace git clone with tarball fetch**

Critical file: `install.sh`, lines 41 and 52–64.

- Remove `require git` (line 41).
- Add `require curl` and `require tar` (both standard on macOS/Linux).
- Replace the three-branch clone block (lines 53–64):
  - Compute tarball URL: default `${DEWEY_REPO%.git}/archive/refs/heads/${DEWEY_REF}.tar.gz` (GitHub layout). Allow override via `DEWEY_TARBALL` env var for non-GitHub hosts.
  - **Dev-checkout detection** (preserves the local-dev and test-sandbox flow): treat as dev checkout *only* if `$DEWEY_DIR/.git` exists. (Tightened per principal review — the previous "guide/SKILL.md + marketplace.json present" heuristic could false-positive against a half-extracted tarball.) For the tests/sandbox flow that doesn't have a `.git/`, the test harness will set a new explicit env var `DEWEY_USE_INPLACE=1` to force in-place use.
  - **Tarball integrity (optional checksum).** If `DEWEY_TARBALL_SHA256` is set, after download run `echo "$DEWEY_TARBALL_SHA256  $tarball_file" | shasum -a 256 -c -` and abort on failure. Optional, not required — preserves the default zero-friction path while letting secure environments lock down integrity.
  - Otherwise: download tarball into a temp dir under `$(mktemp -d)`, `tar -xz --strip-components=1` into a staging subdir.
  - **Atomic swap** (per principal review — fixes race with `refresh.sh` reads): move the existing `$DEWEY_DIR` aside to `$DEWEY_DIR.old`, move staging dir to `$DEWEY_DIR`, then `rm -rf` the old. Single `mv` of a sibling dir on the same filesystem is atomic. No window where the Guide can read a half-written cache.
  - **Destructive-path guard** (per principal review): before any `rm -rf` of `$DEWEY_DIR.old`, assert `[[ "$DEWEY_DIR" == *".claude/dewey"* ]]` and abort otherwise. Cheap insurance against a malformed env var nuking the wrong directory.
  - **Local-edit visibility:** if the swap replaced an existing populated cache that wasn't a dev checkout, print a one-line warning: `Dewey cache refreshed (any local edits in ~/.claude/dewey were overwritten)`. Per principal review — prevents silent surprise.
- Update the usage comment block at the top to drop the git mention. Document `DEWEY_TARBALL`, `DEWEY_TARBALL_SHA256`, and `DEWEY_REF` (which already supports tags — call this out for users who want to pin to a release tag rather than `main`).

**2. `install-dev.sh` — new file, contributor flow**

- Copy of the *current* install.sh git-clone path. Top comment: "For Dewey contributors. Regular users should use install.sh."
- Same behavior as today's install.sh: `require git`, `git clone` / `git pull`, everything else unchanged. This preserves the contributor workflow that wants a live, pull-able checkout.

**3. `README.md` — install instructions**

- Confirm the curl|bash one-liner makes no mention of git.
- Add one line: "No git required. macOS and Linux only for now."
- Add (or extend) a Contributing subsection pointing contributors to `install-dev.sh`.
- Add a new "How Dewey stays current" subsection (see "How updates flow" below).

**4. `tests/run.sh` — extend Layer 4**

The current Layer 4 (around line 304) pre-populates `$SANDBOX_DEWEY` with a non-git copy and exercises the "exists but not git" branch. Under the new `install.sh`, this maps cleanly to the new dev-checkout-detection branch (the sandbox copy contains both `guide/SKILL.md` and `.claude-plugin/marketplace.json`), so all 13 existing sandbox tests should pass unchanged. Verify this.

The current Layer 4 sandbox flow (which uses a non-git copy of the repo as `$DEWEY_DIR`) will be updated to set the new explicit `DEWEY_USE_INPLACE=1` env var to force in-place use, since the dev-checkout heuristic is being tightened to require `.git/`. Existing 13 sandbox tests should still pass after this one-line tweak.

Add new tests (mapped to principal review must-fixes):

- **Tarball install path.** Create a fresh `$SANDBOX2` with no pre-populated `DEWEY_DIR`. Build a local tarball: stage `$SANDBOX2/stage/dewey/` with the repo contents, then `tar -czf dewey.tar.gz -C $SANDBOX2/stage dewey`. Run `install.sh` with `DEWEY_TARBALL=file://$SANDBOX2/dewey.tar.gz`. Assert `$SANDBOX2/.claude/dewey/guide/SKILL.md` exists and matches source, `settings.json` registered, hook installed.
- **No git on PATH.** Re-run `install.sh` under a stripped PATH (e.g. `PATH=/usr/bin:/bin`) and confirm exit 0.
- **Checksum validation passes** when `DEWEY_TARBALL_SHA256` matches the local tarball.
- **Checksum validation fails loudly** when `DEWEY_TARBALL_SHA256` is set but wrong — `install.sh` exits non-zero, `$DEWEY_DIR` is unchanged.
- **Destructive-path guard** rejects an obviously bad `DEWEY_DIR` (e.g. `/tmp/something-else`) — install aborts before deleting anything.
- **Atomic swap.** After a successful tarball install, assert no `$DEWEY_DIR.old` or `$DEWEY_DIR.new` siblings linger.
- **Update freshness.** Run tarball install once, delete a file from `$SANDBOX2/.claude/dewey/plugins/...`, re-run `install.sh`, confirm the file is restored. Add a stray file inside the cache, re-run, confirm it's gone (atomic swap inherently delivers `--delete` semantics — the entire dir is replaced).

**5. `refresh.sh` — periodic cache refresh (the "how do updates flow" answer)**

Without HTTP-at-runtime, the Guide reads stale files until *something* re-downloads the tarball. The mechanism: a refresh script invoked from the existing `SessionStart` hook, gated by a timestamp marker so it runs at most once per 24h and never blocks session start.

- New file `refresh.sh`:
  - **Lock file** (per principal review — prevents concurrent refreshes from racing each other): `LOCK_FILE="$HOME/.claude/dewey-refresh.lock"`. If exists, exit 0 silently. Otherwise `touch "$LOCK_FILE"; trap 'rm -f "$LOCK_FILE"' EXIT`.
  - Reads `$HOME/.claude/dewey-last-refresh` marker. If younger than 24h, exit 0 silently (after releasing lock).
  - Else, factor the tarball-fetch + atomic-swap logic from `install.sh` into a shared shell function (sourced or duplicated — duplicated is fine for v1.0.1 to keep blast radius small) and invoke it. Atomic swap means the Guide cannot observe a half-written cache.
  - On success, `touch` the marker and log timestamp to `$HOME/.claude/dewey-refresh.log` (per principal review #9 — minimal observability so silent staleness is debuggable).
  - On network or extract failure, log to `$HOME/.claude/dewey-refresh.log` and exit 0 — never break the user's session.
  - Skips itself entirely if `$DEWEY_DIR/.git` exists — contributors update via `git pull`.
- Modify `install.sh` to: (a) drop `refresh.sh` next to the existing first-run hook, and (b) extend the first-run hook script to invoke `refresh.sh` in a portable subshell (per principal review — `& disown` is shell-dependent): `( "$HOME/.claude/dewey-refresh.sh" >/dev/null 2>&1 & )`. The parent hook returns immediately; the refresh runs detached without relying on `disown`. The hook stays a single command in `settings.json`.
- Tests: add Layer 4 tests asserting (i) `refresh.sh` exists post-install and is executable, (ii) running `refresh.sh` twice in succession only does work once (marker honored), (iii) running `refresh.sh` with a corrupted/unreachable tarball URL still exits 0 and writes to the log file, (iv) `refresh.sh` is a no-op when `$DEWEY_DIR/.git` exists, (v) **lock file blocks concurrent runs**: create the lock file, run refresh, assert it exits 0 without doing work; then remove the lock and assert it can run again, (vi) **atomic swap leaves no partial state**: simulate a refresh that aborts mid-extract (e.g. corrupt tarball), assert `$DEWEY_DIR` is unchanged afterward (no `.partial` or half-extracted dirs).
- Override: power users can set `DEWEY_REFRESH_INTERVAL=0` to force every-session refresh, or `DEWEY_REFRESH_INTERVAL=-1` to disable. Document in README.

**6. Ownership layer**

Critical files: `plugins/*/.claude-plugin/plugin.json`, new `CODEOWNERS`, `guide/SKILL.md`.

- Add an `owner` field to every `plugin.json` with shape `{ "name": "...", "contact": "..." }` (Slack handle, email, or GitHub handle). Update all four existing plugins: competitive-intelligence, customer-research, ops-essentials, sales-enablement. Use a placeholder owner like `{"name": "CK", "contact": "@ck"}` so the structure is real and tests can validate it; real maintainers fill in via PR.
- Add a `CODEOWNERS` file at repo root following GitHub's syntax: per-directory ownership (`/plugins/competitive-intelligence/ @owner-handle`, etc.) plus a fallback `* @ck` for unowned paths. This is what GitHub uses to auto-request reviews on PRs — no web UI needed, source control is the source of truth.
- Extend Layer 1 of `tests/run.sh` to assert: (a) every `plugin.json` has an `owner.name` and `owner.contact`, (b) `CODEOWNERS` exists at repo root, (c) every plugin directory under `plugins/` has a corresponding line in `CODEOWNERS`. This makes the convention enforced, not advisory.
- Add a new subcommand to `guide/SKILL.md`: §5 Owners (route from `$0 == "owners"`). Behavior: read every `~/.claude/dewey/plugins/*/.claude-plugin/plugin.json`, group by owner, output a table: plugin name → owner name → contact. Add `owners` to the routing list and the menu (item 5: "Find who maintains a skill"). Update the `argument-hint` frontmatter to include `owners`.
- Re-trim the Guide's `description` if adding "owners" pushes it past 250 chars — the test suite already enforces this.
- Update `README.md` and `docs/pr-checklist.md` to document the owner field and CODEOWNERS expectation.

**7. `guide/SKILL.md` — minimal additions only**

Re-read of lines 26–32 confirms the Guide's existing data dependencies (`marketplace.json`, `paths/*.md`, plugin SKILL.md files) are all present after tarball extraction. The only Guide changes are:
- Add the §5 Owners subcommand for the ownership layer above.
- Add `owners` to the routing list and main menu.
- Update `argument-hint`.
- Optionally add a `/dewey update` subcommand that re-invokes `install.sh` after confirmation (see "How updates flow" #3).

No allowed-tools changes, no WebFetch.

## How updates flow (the design answer)

Three update channels, complementary not redundant:

1. **Reference cache** (`~/.claude/dewey/`): refreshed by `refresh.sh` on SessionStart, at most once per 24h, in the background, never blocking. This is what feeds the Guide's `recommend` and `extend` flows — when central adds a new plugin or updates a path, users see it within a day without re-running `install.sh`.
2. **Installed plugins** (the things users actually run): updated by Claude Code's existing per-marketplace `autoUpdate` toggle on `extraKnownMarketplaces`. `install.sh` should set this to `true` by default for `dewey-reference`. Existing primitive — we're just opting in.
3. **The Guide skill itself** (`~/.claude/skills/dewey/SKILL.md`): refreshed only by re-running `install.sh`, because changing the Guide is a privileged operation we don't want happening silently. Add a Guide subcommand `/dewey update` that re-invokes `install.sh` after confirmation. This honors the "always confirm before action" rule for the one update channel that touches a skill the user is actively running.

Document all three in `README.md` under a new "How Dewey stays current" subsection.

## Verification

Run from `/Users/ck/skill-marketplace`:

1. `bash tests/run.sh` — all existing tests pass; new tarball, no-git, refresh, and ownership tests pass.
2. **Manual sandbox without git on PATH:**
   ```
   SANDBOX=$(mktemp -d)
   PATH=/usr/bin:/bin HOME=$SANDBOX bash install.sh
   ```
   Confirm no error, `$SANDBOX/.claude/skills/dewey/SKILL.md` exists, `$SANDBOX/.claude/dewey/.claude-plugin/marketplace.json` exists.
3. **Idempotency:** run `install.sh` twice in the same sandbox; second run succeeds, hooks not duplicated, files refreshed.
4. **Refresh:** force `DEWEY_REFRESH_INTERVAL=0`, run the SessionStart hook, confirm `refresh.sh` ran, then with default interval confirm the second invocation was a no-op.
5. **Dev flow:** `bash install-dev.sh` against a sandbox; `~/.claude/dewey/.git` exists and `git -C ~/.claude/dewey status` works.
6. **Ownership:** `/dewey owners` lists every plugin with owner + contact; `tests/run.sh` enforces every plugin has an owner and a CODEOWNERS line.
7. **End-to-end Guide flow** (manual): post-install sandbox, open Claude Code, `/dewey`, walk `recommend` → `install` for one plugin. Confirm the Guide reads `paths/sales-ae.md` from the tarball-installed dir.

## Out of scope for v1.0.1

- GitHub Action wrapping `tests/run.sh` — defer.
- Making the Guide HTTP-aware (no local cache, fetch `marketplace.json` over the network at runtime) — **rejected**. Adds WebFetch to allowed-tools, complicates failure modes (network errors mid-Guide-flow), and the tarball cache + 24h refresh already covers the update path. Revisit only if telemetry shows users hitting "stale cache" problems.
- Cowork/Chat sync — still v1.1+.

## Review checklist for the second engineer

- [ ] Does the dev-checkout-detection key (`guide/SKILL.md` AND `.claude-plugin/marketplace.json` both present) cleanly cover the local-dev and test-sandbox flows without false positives?
- [ ] Is `DEWEY_TARBALL` override sufficient for non-GitHub hosts (GitLab, Bitbucket, internal Gitea)? Should we also support `DEWEY_TARBALL_HEADER` for auth?
- [ ] Is `rsync --delete` aggressive enough? Will it ever wipe a user's local edits inside `~/.claude/dewey/`? (Answer should be: yes it will, and that's correct because the cache is a snapshot — but document it.)
- [ ] 24h refresh interval — too long, too short, configurable enough?
- [ ] Background refresh on SessionStart: any risk of a half-written cache being read by the Guide mid-refresh? (Mitigation: refresh writes to temp dir then atomically syncs.)
- [ ] CODEOWNERS approach assumes GitHub hosting. Document the fallback for self-hosted Git providers without CODEOWNERS support.
- [ ] Should `/dewey update` ALSO invalidate the 24h refresh marker so the next session pulls fresh?
