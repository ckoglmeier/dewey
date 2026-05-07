# Decision: how to distribute external Classroom plugins

**Status:** Open. Needs an engineering decision before further work on external plugin references.
**Owner:** TBD (next engineer to pick this up)
**Last updated:** 2026-05-06
**Verified against:** Claude Code v2.1.47

## TL;DR

Classroom's marketplace can reference plugins that live in other repos. We attempted three external entries pointing at sub-directories of `ckoglmeier/skills` (`templates/exec-feedback`, `templates/research-assistant`, `templates/template-strategy-feedback`). They had to be removed because **no Claude Code source type currently supports installing a plugin that lives in a sub-path of an external repo**.

We need to decide which of three viable distribution models to adopt before we can re-add external references. Each has real cost. This doc lays out the verified findings, the three options, and the architecture questions that should drive the call.

## Context

Classroom is a thin marketplace. The four in-tree plugins (`competitive-intelligence`, `customer-research`, `ops-essentials`, `sales-enablement`) ship from this repo because they're authored *for* Classroom's audience and reviewed here. Templates that live elsewhere — like the contents of `ckoglmeier/skills/templates/` — were intended to be referenced *by* Classroom's marketplace, not copied into it. The "thin pointer" model avoids drift, keeps Classroom small, and lets upstream evolve at its own pace.

That model assumes Claude Code's plugin system can install from a sub-path of an external repo. As of v2.1.47, it can't.

## Verified findings (2026-05-06)

### 1. `marketplace add` schema acceptance by source type

Tested by registering minimal manifests in a sandbox `HOME` against a fresh Claude Code install:

| Source type | Result |
|---|---|
| `"./relative/path"` (string, in-tree) | ✓ accepted |
| `{"source": "url", "url": "..."}` | ✓ accepted |
| `{"source": "github", "repo": "owner/repo"}` | ✓ accepted |
| `{"source": "npm", "package": "@scope/name"}` | ✓ accepted |
| `{"source": "git", "url": "..."}` | ✗ rejected: `Invalid input` |
| `{"source": "git-subdir", "url": "...", "path": "..."}` | ✗ rejected: `Invalid input` |

The `git-subdir` rejection holds even when the entry is a **literal copy of a working entry from Anthropic's `claude-plugins-official` marketplace** (which still uses `git-subdir` for ~9 of its plugins). So the validator was apparently tightened after the official marketplace was registered, and existing official entries are grandfathered. New marketplaces can no longer use `git-subdir`.

### 2. Sub-path support at install time

The `github` source schema is permissive enough to accept a `path:` field (as well as `subdir:` and `directory:`). All three pass `marketplace add`. But:

- Installing `{"source": "github", "repo": "ckoglmeier/skills", "path": "templates/exec-feedback"}` reports success
- The cache contains the **entire `ckoglmeier/skills` repo**, not just the sub-path
- There's no `.claude-plugin/plugin.json` at the cache root (just a `marketplace.json`, because the upstream is itself a marketplace)
- The plugin is effectively broken — Claude Code's plugin loader can't find a plugin manifest at the expected location

Conclusion: the `github` fetcher silently ignores any sub-path field. There is no working sub-path mechanism for any accepted source type today.

### 3. Layer 3b's offline schema validator is now optimistic

`tests/run.sh` Layer 3b currently accepts `git` and `git-subdir` source entries as valid. Live `marketplace add` rejects them. The lint should be tightened to reject the same set the live validator rejects, otherwise it gives false confidence.

## Requirements the answer must satisfy

A solution needs to:

1. **Install end-to-end via `claude plugin install <name>@classroom`** — registration AND fetcher honor it.
2. **Survive a Claude Code minor-version bump** without further tightening breaking it (so favor schema shapes Anthropic clearly intends to keep, like `github` and `npm`).
3. **Keep ownership clearly attributable** to the upstream maintainer (Classroom doesn't review the content of external plugins — its job is to validate the manifest entry).
4. **Scale to N templates** without Classroom maintenance work growing linearly with N.
5. **Be a real publish/update flow**, not a one-time copy that drifts.

## Three distribution models

### Option A: One GitHub repo per template

Promote each template from a sub-directory of `ckoglmeier/skills` to its own GitHub repository. Manifest entry becomes:

```json
{
  "name": "exec-feedback",
  "source": {"source": "github", "repo": "ckoglmeier/skill-exec-feedback"},
  "description": "...",
  "category": "writing"
}
```

**Pros:**
- Cleanest schema match to what Claude Code natively supports
- Each template gets its own CODEOWNERS, issue tracker, release cadence, and version history
- "Track main" works without `ref:` field (which is currently rejected by the validator anyway)
- Trivially discoverable on GitHub by name

**Cons:**
- N repos to set up and maintain
- The original `ckoglmeier/skills` repo loses its role as the canonical home for templates — either becomes a redirect/index or is sunset
- Cross-template refactors (e.g., shared utility prompts) become multi-repo PRs
- Forking workflow ("clone all my company's skills") becomes harder — there's no single tree

**Migration cost:** ~30 min per template to set up the new repo, transfer history, point Classroom at the new URL. Multiplied by 3 = ~90 min for the current set, or ~10 hours for a hypothetical 20-template library.

### Option B: Per-skill npm packages

Publish each template as an npm package under `@ck-skills/<name>` (or `@classroom-templates/<name>`). Manifest entry becomes:

```json
{
  "name": "exec-feedback",
  "source": {"source": "npm", "package": "@ck-skills/exec-feedback"},
  "description": "...",
  "category": "writing"
}
```

**Pros:**
- npm registry is the distribution mechanism — no GitHub repo proliferation
- Real semantic versioning out of the box (`1.2.3`)
- Pin a specific version per Classroom: `{"source": "npm", "package": "@ck-skills/exec-feedback", "version": "^1.0.0"}`
- npm tooling for searching, deprecating, deprecating versions
- Publish-once, install-many — clean delivery model
- The single upstream `ckoglmeier/skills` repo can stay the dev monorepo; it just publishes N npm packages on release

**Cons:**
- Requires npm publish credentials and an org scope
- Extra publish step on every template change (could be automated with a GitHub Action from the `ckoglmeier/skills` monorepo)
- npm-as-distribution-for-Markdown feels weird at first (but it's literally what Anthropic did with `@anthropic/skills-*` packages, so there's precedent)
- npm package contents are opaque to GitHub-based code reviewers without cross-referencing the source

**Migration cost:** ~1 hour to set up an org scope and publish pipeline; ~5 min per template to publish; ongoing publish step on every update (automatable).

### Option C: Inline into Classroom's `plugins/` directory

Move all three templates into `plugins/exec-feedback/`, `plugins/research-assistant/`, `plugins/template-strategy-feedback/`. Manifest entries become string-source (in-tree) like the existing four plugins.

**Pros:**
- Works today, no upstream dependency
- One place for review, validation, CODEOWNERS, releases
- Best Classroom test coverage — Layer 1-7 lint runs against every file
- Same install pipeline as the other in-tree plugins

**Cons:**
- Defeats the "Classroom is a thin pointer to upstream" goal
- The original `ckoglmeier/skills/templates/` has to either be deleted (drift risk if not) or become a fork that diverges from Classroom's copy
- Classroom maintainer becomes the owner of skills they didn't author — wrong attribution
- Doesn't scale: if 30 teams all want their templates available through Classroom, in-tree means 30 plugins land in *this* repo

**Migration cost:** ~15 min to copy the three templates in, set up CODEOWNERS lines, run tests.

## Architecture questions worth answering before picking

These should drive the choice — list them, get answers, then the right option falls out:

1. **Is `ckoglmeier/skills` still the canonical home for these three templates?** If yes, Classroom is a thin pointer and Option A or B fit. If no (i.e., we're happy to move them), Option C is on the table.

2. **What's the realistic 12-month count of external templates Classroom should reference?** If single digits, Option A is fine. If 20+, Option A's repo proliferation gets painful and B (or a future `git-subdir` un-blocking) becomes necessary.

3. **Do we want pinned versions or always-track-latest?** Today's marketplace entries are mostly bare references with no pinning. If we want pinning (and we probably should for production use), npm's semver is a better fit than github's branch-tracking (which doesn't even accept a `ref:` field today).

4. **Who's in CODEOWNERS for each template?** If the same person owns Classroom and these templates, attribution is moot. If different owners, the in-tree option (C) creates a confusing review fan-out.

5. **What's our policy when Claude Code's validator changes again?** This blocker came from a silent tightening. We should pick a source type Anthropic clearly maintains as a first-class citizen. Both `github` and `npm` qualify; `git`/`git-subdir` were grandfathered and may continue to slip.

6. **Do we want template authors outside our org to contribute?** If yes, the answer should be a model where any GitHub user can publish their own (`github` source pointing at their own repo, or npm package under their own scope). Option C requires PR access to Classroom's repo, which doesn't scale.

7. **Test strategy for external entries:** Layer 3b validates the manifest schema offline. Layer 8 (now empty after we removed the schedule helper) was reserved for opt-in live validation — sparse-clone the upstream, confirm `plugin.json` exists, name matches. Whatever we pick, we need this layer to actually catch what we just demonstrated: *the registration succeeded but the install was broken*. Static schema validation isn't enough.

## Recommended path (with caveats)

If forced to pick today: **Option B (per-skill npm packages)** for these three templates plus any future external ones, with **Option A as the fallback for skill authors who don't want to publish to npm**.

Reasoning:
- npm gives real versioning, which we'll want anyway as soon as canary rollouts or pinning matter
- Single upstream repo (`ckoglmeier/skills`) stays the dev monorepo; npm publish is automatable from a release tag
- Doesn't lock external authors into a particular repo layout — they can structure however they want as long as they `npm publish`
- `@scope/name` namespacing is ergonomic and discoverable
- Aligns with how Anthropic distributes its own skills

This is a recommendation, not a decision. The architecture questions above may push toward A or C for legitimate reasons.

## What changes after the decision lands

Regardless of which option:

1. **Re-add the three external entries to `marketplace.json`** in the chosen source format
2. **Tighten Layer 3b** to reject any source type that current `marketplace add` rejects (`git`, `git-subdir`)
3. **Add the deferred opt-in live validation as Layer 8** — gated by `CLASSROOM_VALIDATE_EXTERNAL=1`, actually attempts to fetch and verify the install works end-to-end. The schedule helper used to live in Layer 8; that slot is free now.
4. **Update `docs/extending-skills.md`** "Adding a plugin that lives in another repo" section to recommend the chosen source type and warn against the rejected ones
5. **Update CLAUDE.md item #1** to mark this resolved

If Option B (npm) wins, additionally:

- Set up `@ck-skills` (or chosen) npm scope
- Add a GitHub Action to `ckoglmeier/skills` that publishes each `templates/<name>/` as a package on release
- Document the publish flow in a new `docs/publishing-templates.md`

If Option A (per-repo) wins:

- Create the new repos, transfer history, set up CODEOWNERS in each
- Document the "spinning out a new template" workflow

If Option C (inline) wins:

- Copy templates into `plugins/`, add CODEOWNERS lines
- Decide what happens to `ckoglmeier/skills/templates/` (delete? README pointer to Classroom?)

## Related

- [`docs/extending-skills.md`](../extending-skills.md) — current "Adding a plugin that lives in another repo" section, which references `git-subdir` and needs updating regardless of which option wins
- [`tests/run.sh`](../../tests/run.sh) Layer 3b — the schema validator that needs tightening
- CLAUDE.md item #1 — todo entry tracking this blocker
- v1.2.0 release notes — explicitly called out the empty Layer 8 slot as the home for live validation
