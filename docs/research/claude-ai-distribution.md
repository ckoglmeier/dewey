# Research: pushing Classroom plugins to claude.ai users

**Date:** 2026-05-06
**Verified against:** Anthropic public docs, Claude API beta `skills-2025-10-02`, claude.ai web UI as documented
**Tracked in CLAUDE.md as todo #2 (Strategic / design)**

## Summary

Anthropic offers four distinct distribution channels that touch claude.ai. Each has different mechanics, scope, and admin model. **None of them today supports the automated "push Classroom's catalog into a customer org's claude.ai" workflow Classroom needs**, but the canonical Anthropic feature request that would unlock it (linking a Git repo as the org skill source) is **open and acknowledged** — Classroom slots in directly when it ships.

The honest current state: defer claude.ai web distribution. Build nothing speculatively. Watch [anthropics/claude-code#28729](https://github.com/anthropics/claude-code/issues/28729). Slot in when Anthropic ships.

## The four distribution channels

### 1. Skills API (`POST /v1/skills`, beta header `skills-2025-10-02`)

Programmatic, scoped to the API key holder's workspace.

```bash
curl -X POST "https://api.anthropic.com/v1/skills" \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "anthropic-beta: skills-2025-10-02" \
  -F "display_title=My Skill" \
  -F "files[]=@my_skill.zip"
```

- Format: ZIP archive OR individual files via multipart. SKILL.md required at root. 30MB limit.
- Used by: developers building apps with the Claude API. Skills load via the `container` parameter on Messages API requests.
- **Not visible in claude.ai web Chat.** This is the API surface, not the consumer surface.
- Endpoints: `POST /v1/skills`, `GET /v1/skills`, `GET /v1/skills/{id}`, `DELETE /v1/skills/{id}`, `POST /v1/skills/{id}/versions`, `GET /v1/skills/{id}/versions`.

**Relevance to Classroom:** small. Could be useful as an optional `classroom-export-api.sh` for the niche of Classroom users who also build with the Claude API. Not the headline.

### 2. claude.ai web — per-user manual upload

The default consumer path.

- User: Settings → Customize → Skills → "+" → Upload a skill (ZIP)
- Plans: Free, Pro, Max, Team, Enterprise (with code execution enabled)
- Scope: per-user only. Doesn't propagate.
- ZIP must contain a single skill folder with SKILL.md at the root.

**Relevance to Classroom:** could ship a `classroom-export-chat.sh` that produces ZIPs per skill. User uploads each manually. Painful workflow — user has to re-upload after every Classroom update. Low ROI; not recommended.

### 3. claude.ai web — org-wide provisioning (Team/Enterprise admin)

The path Classroom actually wants.

- Owner: Organization settings → Skills → upload ZIP (becomes available to all org members)
- Plans: Team and Enterprise only
- Scope: org-wide. Users can toggle individual skills on/off but the catalog comes from the admin.
- Prerequisite: owner enables "Code execution and file creation" + "Skills" in Organization settings.

**Critical gap: no public API.** The admin UI calls internal endpoints (`upload-org-skill`, `delete-org-skill`) but these use session-cookie auth — not suitable for CI/CD or third-party tools.

**Open feature request:** [anthropics/claude-code#28729](https://github.com/anthropics/claude-code/issues/28729) — "Link a source control repo as the source for organization skills." Status: **OPEN, acknowledged by Anthropic**. The proposal in the issue is *literally what Classroom does* (admin links a Git repo URL → org skills auto-sync from it). The duplicate that bubbled up to it ([#49530](https://github.com/anthropics/claude-code/issues/49530), now closed) explicitly named CI/CD-from-GitHub-Action as the missing capability.

**Relevance to Classroom:** highest. The moment #28729 ships, Classroom is positioned to slot in: an admin links their `classroom-fork-url` as the org skill source, all org members get the canonical skills automatically. Zero code changes on our side likely needed beyond updating `docs/` to point at the new admin flow.

### 4. Cowork — private plugin marketplaces (Team/Enterprise admin, separate from #3)

Announced February 2026 in the Cowork-plugins-for-enterprise blog post. Different surface (Cowork desktop app), different mechanism than claude.ai web.

- Admin: creates org-specific plugin marketplace via Cowork admin UI
- Sources: predefined plugin types, plus **private GitHub repositories as plugin sources (in private beta as of Feb 2026)**
- Capabilities: per-user provisioning, auto-install, central control
- Reach: Cowork users in the org (which already share `~/.claude/` with Claude Code, so plugins propagate to both)

**Relevance to Classroom:** Cowork is already reachable today via the shared `~/.claude/` filesystem. The private-marketplace mechanism is a stronger admin story for *org-managed* installs (auto-install, per-user provisioning) than our `curl | bash` install path. When the private-GitHub-source feature exits beta, an enterprise admin can register Classroom as the org's private marketplace via that mechanism. Same outcome as #28729 for Cowork specifically.

## The "no cross-surface sync" wall

Pulled out as its own section because it's the largest architectural reality:

> **Custom Skills do not sync across surfaces.** Skills uploaded to the API are not available on claude.ai or in Claude Code, and vice versa. Each surface requires separate uploads and management.
> *— Anthropic Skills for Enterprise docs*

This means even when #28729 ships, claude.ai-web-org-wide-provisioning is its own pipe. A skill pushed there isn't automatically in Cowork's marketplace, isn't on the Claude Code CLI side, isn't in the Skills API for SDK users. Each surface is its own world.

For Classroom this means: even the perfect "link Git repo as org skill source" feature only lights up *one* surface at a time. To fully cover an enterprise across all four surfaces, Classroom would need to push:
- The same Git repo into the claude.ai org-skills source (when that ships)
- The same Git repo into the Cowork private-marketplace source (when that's GA)
- An automated `/v1/skills` upload pipeline for API users
- The existing `~/.claude/` install for Code/Cowork local

That's a real story but not a today-story.

## Honest assessment for Classroom's roadmap

### What we should do today

**Nothing implementation-wise on the claude.ai side.** Specifically:

- ❌ Don't build the per-user ZIP exporter (Channel 2). Painful workflow, low value, sets up bad habits.
- ❌ Don't build a Skills API exporter (Channel 1). Niche audience; users who care can write the upload themselves in 10 lines.
- ❌ Don't try to scrape the admin UI's session-cookie endpoints (Channel 3). Fragile, against Anthropic's intent, breaks on every UI change.

**What we should do:**

- ✓ Update CLAUDE.md todo #2 to reflect that the answer is "wait for Anthropic; no useful work to do now."
- ✓ Add a watch on [anthropics/claude-code#28729](https://github.com/anthropics/claude-code/issues/28729) so we know when it ships.
- ✓ Document the four channels in `docs/surfaces.md` so adopters understand what's reachable today vs deferred.

### When #28729 ships

The slot-in work is small:

1. Verify Classroom's marketplace.json layout works as a "Git source for org skills" (the issue suggests it should — Anthropic's proposal mirrors Classroom's mental model).
2. Update `README.md` "Adopting Classroom for your company" with the admin flow (paste your fork URL into Organization settings → Skills source).
3. Possibly add a `classroom-validate-org-skills.sh` helper (subset of Layer 8) the admin can run before linking.

Estimated effort when it ships: ~half a day, mostly docs.

### When Cowork private-GitHub-source exits beta

Same shape — ~half a day of docs work pointing the admin at Classroom's repo URL.

### Optional — Skills API exporter (`/v1/skills`)

Audience: Classroom users who also build apps with the Claude API and want their company's canonical skills available there too. Probably small.

If we ever build this, the shape is straightforward: a `classroom-export-api.sh` helper that walks `~/.claude/classroom/plugins/*/skills/*/SKILL.md`, packages each as a ZIP, POSTs to `/v1/skills`. Maybe ~2 hours of work. **Defer until someone asks for it.**

## The strategic read

Classroom's design assumption — "publish once, install many across surfaces" — is **partially correct today** (Code + Cowork + Codex via our existing mechanisms) and **structurally aligned with where Anthropic is going** (Channel 3's #28729 + Channel 4's private marketplaces both point at "link a Git repo, propagate to users" as the eventual model).

We don't need to bend our design to fit claude.ai web. We need to wait for Anthropic to ship the integration point that already matches our shape, then plug in.

The risk: Anthropic may take a year+ to ship #28729, or may ship it with a substantially different schema than the issue describes. Both are mitigatable — once they ship, our slot-in cost is small enough that even significant rework is manageable.

## Open follow-ups (not in scope of this research)

- Subscribe (or have CK subscribe) to anthropics/claude-code#28729 for status updates.
- When Anthropic ships #28729, run a verification cycle (probably ~1 hour) before claiming Classroom supports the org-skills source path.
- Consider whether the Cowork private-marketplace beta is worth chasing access to — could be 6+ months ahead of #28729.

## Sources

Primary docs and issues:
- [Skills for enterprise (platform.claude.com)](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/enterprise)
- [Using Skills with the API (platform.claude.com)](https://platform.claude.com/docs/en/build-with-claude/skills-guide)
- [Use Skills in Claude (support.claude.com)](https://support.claude.com/en/articles/12512180-use-skills-in-claude)
- [Provision and manage Skills for your organization (support.claude.com)](https://support.claude.com/en/articles/13119606-provision-and-manage-skills-for-your-organization)
- [Cowork and plugins for teams across the enterprise (claude.com blog)](https://claude.com/blog/cowork-plugins-across-enterprise)
- [Issue #28729 — Link a source control repo as the source for organization skills (anthropics/claude-code, OPEN)](https://github.com/anthropics/claude-code/issues/28729)
- [Issue #49530 — API for organization-level skill management (anthropics/claude-code, CLOSED as duplicate of #28729)](https://github.com/anthropics/claude-code/issues/49530)
