# Admin onboarding guide

**Who this is for:** the ops lead, RevOps manager, or team admin who owns "which skills does my team use." You don't need to be an engineer to run this flow — the skill does the technical steps with you.

## The one command to start

```
/dewey-admin-setup
```

Install the `admin` plugin first if you haven't:

```
claude plugin install admin@dewey
```

Then run `/dewey-admin-setup`. The skill will guide you through the rest.

## What the six stages do

| Stage | What happens | Time |
|-------|-------------|------|
| 0 — Prerequisites | Checks `gh` auth and whether your fork exists. Offers a fork walkthrough, a copy-paste ask for your GitHub admin, or a shortcut to the demo. | 2 min |
| 1 — Discover the org | Asks about your company, teams, and roles. Builds an org profile reused by every later stage. | 5 min |
| 2 — Seed canonical context | Builds four context bundles (company identity, ICP, brand voice, positioning) from templates tuned by Stage 1 answers. Submits as PRs against your fork. | 15–20 min |
| 3 — Draft role paths | Creates one curated skill bundle per role (e.g., sales-ae, cs-manager). PRs against your fork. Team leads refine these over time. | 10 min |
| 4 — Suggest plugins | Maps your teams to the in-tree plugins. Advisory only — no writes here. | 5 min |
| 5 — Live demo | Installs `ops-essentials` and drafts your own weekly status update in real time. Shows what your team will experience in 90 seconds. | 5 min |
| 6 — Invite first wave | Generates copy-paste install messages for your first three users, personalized by role. | 5 min |

## Want a taste before committing to the fork?

Stage 5's demo works before any fork exists. When the skill asks about prerequisites at Stage 0, say "skip to demo." You'll see what Dewey does for a real person in five minutes — then decide if you want to continue with the full setup.

## After the flow

- PRs from Stages 2 and 3 will be in your fork's PR tab — review and merge them.
- Once merged, any team member who runs `/dewey recommend` gets the curated paths you set up.
- To update canonical context later: `/dewey propose update-context`.
- To add a new role path: `/dewey curate-path`.

## Questions

Run `/dewey owners` to find who to ping for any plugin.
