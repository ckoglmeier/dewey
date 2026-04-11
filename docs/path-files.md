# Path files

A **path file** is a curated bundle of plugins for a specific role. It lives at `paths/<role>.md` in the central Classroom repo and tells the Guide which plugins to recommend when a user identifies as that role.

Path files are how **team leaders curate without building**. The leader's entire authoring surface is one markdown file. They never write a skill — they pick from skills that already exist in the marketplace and explain why each one matters for their team.

This is a deliberate design choice. The Ramp Glass team's biggest finding was that the people who got value were the ones who installed a skill on day one and immediately got a result. The path file is what makes day one possible: a new hire opens Claude, runs `/classroom`, says their role, and gets the right 3–5 skills installed in 60 seconds.

## Format

```markdown
# Path: <role>

Curated skills for <role>. Install these on day one.

## Recommended plugins

- **<plugin-name>** — <why this matters for this role, in one sentence>
- **<plugin-name>** — <why this matters for this role, in one sentence>
- **<plugin-name>** — <why this matters for this role, in one sentence>

## How to use this path

[Optional: a 2–3 sentence "what to try first" — what's the wow moment for this role?]

## Maintained by

<team lead name>, last updated <date>
```

## Rules

1. **Filename = role identifier.** Lowercase, hyphenated, no extension confusion. `sales-ae.md`, `ops-analyst.md`, `cx-engineer.md`. The Guide matches user-stated roles to filenames.
2. **3–6 plugins maximum.** Fewer is better. If your path has 8 plugins, you're not curating — you're listing. Cut.
3. **The "why" is mandatory.** A bullet that just names a plugin without explaining why this role needs it isn't a recommendation, it's a menu. The "why" is what makes the path feel like advice from a senior teammate, which is what makes a non-technical user trust it.
4. **Speak in the role's language.** "Deals stall when AEs can't articulate competitive differences" is better than "competitive-intelligence provides competitive analysis capabilities." Talk about the user's actual problem.
5. **Maintained by** is non-negotiable. When a path goes stale, somebody has to be on the hook. Anonymous paths get ignored.

## Updating a path

Path files live in the central Classroom repo and update through PR. The fastest way to draft one is:

```
/classroom curate-path
```

The Guide will walk a team lead through the format, draft the file, and (with `gh` installed) open a PR for them. See the Guide skill for details.

## What a path is NOT

- **Not a skill itself.** A path doesn't have logic. It's a recommendation list.
- **Not the only way to install plugins.** Users can always run `/classroom install` to browse the full marketplace and pick whatever they want. Paths are for the day-one default.
- **Not permanent.** When the team's needs change, the team lead updates the file and opens a new PR. Paths should drift over time as the team learns.
