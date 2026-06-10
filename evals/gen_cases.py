#!/usr/bin/env python3
"""Generate evals/cases/trigger_routing.jsonl from the in-tree SKILL.md files.

Scans plugins/*/skills/*/SKILL.md, skips user-invocable: false skills,
and emits one JSON line per (skill, trigger) pair.

Usage:
    python3 evals/gen_cases.py               # writes evals/cases/trigger_routing.jsonl
    python3 evals/gen_cases.py --stdout      # prints to stdout instead

The output file is committed so the eval has cases even without running the
generator. Regenerate whenever skills or triggers change.
"""
from __future__ import annotations
import glob
import json
import os
import re
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUTPUT_PATH = os.path.join(REPO_ROOT, "evals", "cases", "trigger_routing.jsonl")


# ---------------------------------------------------------------------------
# Frontmatter parsing (stdlib only; mirrors check_triggers.py conventions)
# ---------------------------------------------------------------------------

def parse_frontmatter(text: str) -> tuple[list[str], bool]:
    """Return (fm_lines, found)."""
    m = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
    if not m:
        return [], False
    return m.group(1).splitlines(), True


def parse_scalar(fm_lines: list[str], key: str) -> str | None:
    value_parts: list[str] = []
    in_block = False
    for line in fm_lines:
        if in_block:
            if line.startswith("  ") or line.startswith("\t"):
                value_parts.append(line.strip())
                continue
            else:
                break
        m = re.match(r"^" + re.escape(key) + r"\s*:\s*(.*)", line)
        if m:
            rest = m.group(1).strip()
            if rest in (">", "|", ""):
                in_block = True
                continue
            return rest.strip("\"'")
    if value_parts:
        return " ".join(value_parts)
    return None


def parse_triggers(fm_lines: list[str]) -> list[str] | None:
    in_triggers = False
    triggers: list[str] = []
    found_key = False
    for line in fm_lines:
        if re.match(r"^triggers\s*:", line):
            found_key = True
            rest = line.split(":", 1)[1].strip()
            if rest and rest not in (">", "|"):
                return [rest.strip("\"'")]
            in_triggers = True
            continue
        if in_triggers:
            m = re.match(r'^  - ["\'](.*)["\']$', line)
            if m:
                triggers.append(m.group(1))
                continue
            m2 = re.match(r'^  - (.+)$', line)
            if m2:
                triggers.append(m2.group(1).strip().strip("\"'"))
                continue
            if line and not line.startswith((" ", "\t", "-")):
                in_triggers = False
    if not found_key:
        return None
    return triggers


# ---------------------------------------------------------------------------
# Main generator
# ---------------------------------------------------------------------------

def generate() -> list[dict]:
    """Return sorted list of case dicts."""
    pattern = os.path.join(REPO_ROOT, "plugins", "*", "skills", "*", "SKILL.md")
    skill_files = sorted(glob.glob(pattern))

    cases: list[dict] = []

    for skill_md in skill_files:
        # Derive plugin and skill names from path
        parts = skill_md.split(os.sep)
        # ...plugins/<plugin>/skills/<skill>/SKILL.md
        try:
            plugins_idx = parts.index("plugins")
            plugin_name = parts[plugins_idx + 1]
            skill_dir = parts[plugins_idx + 3]
        except (ValueError, IndexError):
            continue

        with open(skill_md, encoding="utf-8") as f:
            text = f.read()

        fm_lines, has_fm = parse_frontmatter(text)
        if not has_fm:
            continue

        # Skip orchestrator-internal skills
        invocable = parse_scalar(fm_lines, "user-invocable")
        if invocable is not None and invocable.lower() == "false":
            continue

        name = parse_scalar(fm_lines, "name") or skill_dir
        triggers = parse_triggers(fm_lines)
        if not triggers:
            continue

        for trigger in triggers:
            trigger = trigger.strip()
            if not trigger:
                continue
            cases.append({
                "skill": name,
                "plugin": plugin_name,
                "trigger": trigger,
                "expect_skill": name,
            })

    return cases


def main() -> None:
    to_stdout = "--stdout" in sys.argv

    cases = generate()

    lines = [json.dumps(case, ensure_ascii=False) for case in cases]
    output = "\n".join(lines) + ("\n" if lines else "")

    if to_stdout:
        sys.stdout.write(output)
    else:
        os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
        with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
            f.write(output)
        print(f"Generated {len(cases)} trigger cases → {os.path.relpath(OUTPUT_PATH, REPO_ROOT)}")


if __name__ == "__main__":
    main()
