#!/usr/bin/env python3
"""Validate triggers: frontmatter field in every in-tree SKILL.md.

Usage: check_triggers.py [repo_root]
       Defaults to cwd if repo_root is omitted.

Rules:
  FAIL  — skill has no triggers: field at all
  FAIL  — any trigger is empty or > 200 chars
  WARN  — skill has fewer than 3 triggers
  FAIL  — a trigger shares zero significant words with the skill's
          description: + name: fields
  FAIL  — a skill with user-invocable: false has a triggers: field
          (orchestrator-internal skills must not be user-routable);
          such skills are otherwise exempt from the triggers requirement

Significant words: lowercase, punctuation stripped, stop words and
words < 3 chars removed.

Exit 0 if no failures; 1 if any failure.
"""
from __future__ import annotations
import os
import re
import sys
import glob

STOP_WORDS = {
    "a", "an", "the", "for", "to", "of", "in", "on", "with", "and", "or",
    "my", "our", "this", "that", "is", "are", "it", "at", "by", "from",
    "as", "be", "we", "i", "you", "after", "before", "what", "how",
}

MAX_TRIGGER_LEN = 200


def significant_words(text: str) -> set[str]:
    """Return lowercase words after stripping punctuation, dropping stop words and short words."""
    words = re.sub(r"[^a-zA-Z0-9\s-]", " ", text).lower().split()
    return {w for w in words if len(w) >= 3 and w not in STOP_WORDS}


def parse_frontmatter(text: str):
    """Return (frontmatter_lines, found) where found = True if --- delimiters exist."""
    m = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
    if not m:
        return [], False
    return m.group(1).splitlines(), True


def parse_scalar_field(fm_lines: list[str], key: str) -> str | None:
    """Extract a single-line or folded/literal scalar value for `key:` from frontmatter lines."""
    value_parts: list[str] = []
    in_block = False
    for line in fm_lines:
        if in_block:
            # continuation of a block scalar (>, |) — collect indented lines
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
    """Return list of trigger strings, or None if triggers: key is absent."""
    in_triggers = False
    triggers: list[str] = []
    found_key = False
    for line in fm_lines:
        if re.match(r"^triggers\s*:", line):
            found_key = True
            rest = line.split(":", 1)[1].strip()
            if rest and rest not in (">", "|"):
                # inline (not expected by convention, but handle gracefully)
                return [rest.strip("\"'")]
            in_triggers = True
            continue
        if in_triggers:
            m = re.match(r'^  - ["\'](.*)["\']$', line)
            if m:
                triggers.append(m.group(1))
                continue
            # also accept unquoted list items
            m2 = re.match(r'^  - (.+)$', line)
            if m2:
                triggers.append(m2.group(1).strip().strip("\"'"))
                continue
            # end of the block
            if line and not line.startswith((" ", "\t", "-")):
                in_triggers = False
    if not found_key:
        return None
    return triggers


def check_skill(skill_md: str) -> tuple[list[str], list[str]]:
    """Return (failures, warnings) for a single SKILL.md file."""
    failures: list[str] = []
    warnings: list[str] = []

    with open(skill_md) as f:
        text = f.read()

    fm_lines, has_fm = parse_frontmatter(text)
    if not has_fm:
        failures.append(f"{skill_md}: no frontmatter found")
        return failures, warnings

    name_val = parse_scalar_field(fm_lines, "name") or ""
    desc_val = parse_scalar_field(fm_lines, "description") or ""
    invocable = parse_scalar_field(fm_lines, "user-invocable")
    triggers = parse_triggers(fm_lines)

    if invocable is not None and invocable.lower() == "false":
        # Orchestrator-internal skill: users never invoke it, so triggers are
        # the wrong genre here — they'd let the router bypass the orchestrator.
        if triggers is not None:
            failures.append(
                f"{skill_md}: declares user-invocable: false but has a triggers: "
                f"field — remove the triggers (routing must go via the orchestrator)"
            )
        return failures, warnings

    if triggers is None:
        failures.append(f"{skill_md}: missing triggers: field")
        return failures, warnings

    if len(triggers) < 3:
        warnings.append(f"WARN: {skill_md}: only {len(triggers)} trigger(s) — recommend at least 3")

    # Significant words from description + name (name tokens split on hyphens)
    name_tokens = name_val.replace("-", " ")
    ref_words = significant_words(desc_val + " " + name_tokens)

    for trigger in triggers:
        trigger_stripped = trigger.strip()
        if not trigger_stripped:
            failures.append(f"{skill_md}: empty trigger string")
            continue
        if len(trigger_stripped) > MAX_TRIGGER_LEN:
            failures.append(
                f"{skill_md}: trigger exceeds {MAX_TRIGGER_LEN} chars "
                f"({len(trigger_stripped)}): {trigger_stripped[:60]!r}..."
            )
            continue
        tw = significant_words(trigger_stripped)
        if tw and ref_words and not tw.intersection(ref_words):
            failures.append(
                f"{skill_md}: trigger has no word overlap with description+name: "
                f"{trigger_stripped!r}"
            )

    return failures, warnings


def main() -> int:
    repo_root = sys.argv[1] if len(sys.argv) > 1 else "."
    pattern = os.path.join(repo_root, "plugins", "*", "skills", "*", "SKILL.md")
    skill_files = sorted(glob.glob(pattern))

    if not skill_files:
        print(f"check_triggers: no SKILL.md files found under {repo_root}/plugins/")
        return 0

    total = 0
    all_failures: list[str] = []
    all_warnings: list[str] = []

    for skill_md in skill_files:
        total += 1
        failures, warnings = check_skill(skill_md)
        rel = os.path.relpath(skill_md, repo_root)
        if failures:
            for msg in failures:
                print(f"FAIL: {msg}")
        else:
            print(f"ok:   {rel}")
        all_failures.extend(failures)
        for w in warnings:
            print(w, file=sys.stderr)
        all_warnings.extend(warnings)

    print(
        f"\ncheck_triggers: {total} skill(s) checked, "
        f"{len(all_failures)} failure(s), {len(all_warnings)} warning(s)"
    )

    return 1 if all_failures else 0


if __name__ == "__main__":
    sys.exit(main())
