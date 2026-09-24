#!/usr/bin/env python3
"""Mirror each skill's `triggers:` list into the official `when_to_use:` field.

Claude Code decides whether to invoke a skill from its `description` and
`when_to_use` frontmatter (combined, truncated at 1,536 characters). `triggers:`
is a Dewey authoring convention that no runtime reads — it feeds the lint and the
eval harness only. This script renders the triggers into `when_to_use` as a
folded block scalar so the example requests authors write actually influence
routing, and Layer 15 fails if the two drift.

Usage:
    python3 scripts/sync-when-to-use.py           # rewrite when_to_use in every in-tree SKILL.md
    python3 scripts/sync-when-to-use.py --check   # exit 1 if any skill is stale

Skills without `triggers:` (e.g. `user-invocable: false` orchestrator internals)
are left untouched.
"""
from __future__ import annotations
import glob
import os
import re
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PATTERN = os.path.join(REPO_ROOT, "plugins", "*", "skills", "*", "SKILL.md")
KEY = "when_to_use"
BLOCK_STARTS = (">", "|", ">-", "|-", ">+", "|+")


def split_frontmatter(text: str):
    m = re.match(r"^---\n(.*?)\n---\n(.*)\Z", text, re.DOTALL)
    if not m:
        return None, None
    return m.group(1).split("\n"), m.group(2)


def parse_triggers(lines: list[str]) -> tuple[list[str] | None, int, int]:
    """Return (triggers, start_index, end_index_exclusive) or (None, -1, -1)."""
    for i, line in enumerate(lines):
        if re.match(r"^triggers\s*:", line):
            rest = line.split(":", 1)[1].strip()
            if rest and rest not in BLOCK_STARTS:
                return [rest.strip("\"'")], i, i + 1
            triggers: list[str] = []
            j = i + 1
            while j < len(lines):
                l = lines[j]
                m = re.match(r'^  - ["\'](.*)["\']$', l)
                if m:
                    triggers.append(m.group(1))
                    j += 1
                    continue
                m2 = re.match(r"^  - (.+)$", l)
                if m2:
                    triggers.append(m2.group(1).strip().strip("\"'"))
                    j += 1
                    continue
                break
            return triggers, i, j
    return None, -1, -1


def find_key_block(lines: list[str], key: str) -> tuple[int, int]:
    """Return (start, end_exclusive) of an existing `key:` scalar, or (-1, -1)."""
    for i, line in enumerate(lines):
        if re.match(r"^" + re.escape(key) + r"\s*:", line):
            j = i + 1
            rest = line.split(":", 1)[1].strip()
            if rest in BLOCK_STARTS or rest == "":
                while j < len(lines) and (lines[j].startswith("  ") or lines[j].startswith("\t") or lines[j] == ""):
                    if lines[j] == "" and (j + 1 >= len(lines) or not lines[j + 1].startswith("  ")):
                        break
                    j += 1
            return i, j
    return -1, -1


def render(triggers: list[str]) -> list[str]:
    """Folded block scalar: no escaping needed, newlines fold to spaces."""
    out = [f"{KEY}: >-"]
    for idx, t in enumerate(triggers):
        sep = ";" if idx < len(triggers) - 1 else "."
        prefix = "  Example requests: " if idx == 0 else "  "
        out.append(f'{prefix}"{t}"{sep}')
    return out


def rewrite(text: str) -> str | None:
    lines, body = split_frontmatter(text)
    if lines is None:
        return None
    triggers, t_start, t_end = parse_triggers(lines)
    if not triggers:
        return None
    k_start, k_end = find_key_block(lines, KEY)
    if k_start != -1:
        del lines[k_start:k_end]
        if k_start < t_start:
            shift = k_end - k_start
            t_start -= shift
            t_end -= shift
    lines[t_end:t_end] = render(triggers)
    return "---\n" + "\n".join(lines) + "\n---\n" + body


def main() -> int:
    check = "--check" in sys.argv
    stale: list[str] = []
    changed = 0
    for path in sorted(glob.glob(PATTERN)):
        with open(path, encoding="utf-8") as f:
            text = f.read()
        new = rewrite(text)
        if new is None or new == text:
            continue
        rel = os.path.relpath(path, REPO_ROOT)
        if check:
            stale.append(rel)
        else:
            with open(path, "w", encoding="utf-8") as f:
                f.write(new)
            changed += 1
            print(f"updated {rel}")
    if check:
        if stale:
            print("when_to_use is stale in:\n  " + "\n  ".join(stale) + "\nrun: python3 scripts/sync-when-to-use.py")
            return 1
        print("ok: when_to_use matches triggers in every skill")
        return 0
    print(f"{changed} skill(s) updated")
    return 0


if __name__ == "__main__":
    sys.exit(main())
