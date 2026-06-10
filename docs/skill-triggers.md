# Skill triggers

The `triggers:` field in a SKILL.md frontmatter gives the auto-routing system concrete examples of the user utterances that should invoke this skill. Three to five triggers is the right range.

## Format

```yaml
---
name: research-competitive-analysis
description: >
  Run a competitive analysis — landscape scans, competitor profiles, positioning
  matrix, and strategic implications. Use when someone asks about competitors...
triggers:
  - "do a competitive analysis of the sales engagement software landscape"
  - "who are we up against in mid-market HRIS"
  - "how does Gong compare to our product in competitive deals"
  - "what would a buyer choose instead of us and why"
---
```

Each trigger is a quoted string on its own line under `triggers:`. Keep every trigger at or under 200 characters.

## Writing good triggers

A trigger should read like something a real user would type, not like a paraphrase of the description. Vary phrasing across your trigger set — different vocabulary, different levels of specificity:

- One trigger that names the task directly ("do a competitive analysis of X")
- One that uses natural, informal language ("who are we up against in Y")
- One that references a specific situation ("how does X compare to our product in deals")
- Optionally one that's a follow-on question ("what would a buyer choose instead")

Avoid triggers that are just the description reworded. The value is showing the range of surface forms a user might use to reach this skill.

## What the lint enforces

Layer 15 (`bash tests/run.sh`) runs two checks against every in-tree SKILL.md:

**`check_triggers.py` (hard failures)**

- Skill has no `triggers:` field at all
- Any trigger is empty or longer than 200 characters
- A trigger shares zero significant words with the skill's `description:` and `name:` fields (stop words, punctuation, and words under 3 characters are excluded before comparison — one overlap word is enough to pass)

**`check_triggers.py` (warnings, printed to stderr, do not fail the suite)**

- Fewer than 3 triggers

**`check_description_quality.py` (hard failures)**

- Description shorter than 50 characters or longer than 250 characters
- Description first word (or first word after a short product-name prefix sentence of ≤ 4 words) is one of: `helps`, `assists`, `supports`, `provides`

**`check_description_quality.py` (warnings)**

- Description contains none of: `use when`, `when the user`, `use this`, `trigger`

## Running the checks

```bash
bash tests/run.sh
# or just the triggers check against one plugin:
python3 tests/lib/check_triggers.py .
python3 tests/lib/check_description_quality.py .
```

Both scripts accept the repo root as an optional positional argument (defaults to cwd).
