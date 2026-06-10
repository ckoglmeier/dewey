#!/usr/bin/env python3
"""Validate description: quality in every in-tree SKILL.md and guide/SKILL.md.

Usage: check_description_quality.py [repo_root]
       Defaults to cwd if repo_root is omitted.

Rules:
  FAIL  — description length < 50 or > 250 chars
  FAIL  — first content word is a vague verb:
          helps, assists, supports, provides (case-insensitive)
          (also checked after a short leading "Xxx Yyy. " sentence of <= 4 words)
  WARN  — description contains none of: "use when", "when the user",
          "use this", "trigger"

Exit 0 if no failures; 1 if any failure.
"""
from __future__ import annotations
import os
import re
import sys
import glob

VAGUE_VERBS = {"helps", "assists", "supports", "provides"}
TRIGGER_PATTERNS = ["use when", "when the user", "use this", "trigger"]

MIN_LEN = 50
MAX_LEN = 250


def parse_frontmatter(text: str):
    """Return (frontmatter_lines, found)."""
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


def first_content_word(text: str) -> str:
    """Return the first alphabetic word from text, lowercased."""
    m = re.search(r"[a-zA-Z]+", text)
    return m.group(0).lower() if m else ""


def leading_sentence_word_count(text: str) -> tuple[int, str]:
    """If text starts with a sentence ending in '. ', return (word_count, rest).
    Returns (0, text) if no leading sentence found."""
    m = re.match(r"^([^.]+\.\s+)(.*)", text, re.DOTALL)
    if not m:
        return 0, text
    sentence = m.group(1).strip()
    rest = m.group(2).strip()
    words = sentence.split()
    return len(words), rest


def check_skill(skill_md: str) -> tuple[list[str], list[str]]:
    """Return (failures, warnings)."""
    failures: list[str] = []
    warnings: list[str] = []

    with open(skill_md) as f:
        text = f.read()

    fm_lines, has_fm = parse_frontmatter(text)
    if not has_fm:
        failures.append(f"{skill_md}: no frontmatter found")
        return failures, warnings

    desc = parse_scalar_field(fm_lines, "description")
    if desc is None:
        failures.append(f"{skill_md}: missing description: field")
        return failures, warnings

    desc = desc.strip()

    # Length check
    if len(desc) < MIN_LEN:
        failures.append(
            f"{skill_md}: description too short ({len(desc)} chars, min {MIN_LEN})"
        )
    elif len(desc) > MAX_LEN:
        failures.append(
            f"{skill_md}: description too long ({len(desc)} chars, max {MAX_LEN})"
        )

    # Vague-verb check on the first content word
    first_word = first_content_word(desc)
    if first_word in VAGUE_VERBS:
        failures.append(
            f"{skill_md}: description starts with vague verb {first_word!r} — "
            f"use an action verb (e.g. Drafts, Analyzes, Generates, Identifies)"
        )
    else:
        # Also check first word after a short leading sentence (<=4 words)
        word_count, rest = leading_sentence_word_count(desc)
        if 0 < word_count <= 4 and rest:
            second_first = first_content_word(rest)
            if second_first in VAGUE_VERBS:
                failures.append(
                    f"{skill_md}: description starts with {desc.split('.')[0]!r} "
                    f"then vague verb {second_first!r} — "
                    f"use an action verb after the product-name prefix"
                )

    # Warn if no trigger-language pattern found
    desc_lower = desc.lower()
    if not any(pat in desc_lower for pat in TRIGGER_PATTERNS):
        warnings.append(
            f"WARN: {skill_md}: description contains no trigger language "
            f"(\"use when\", \"when the user\", \"use this\", \"trigger\")"
        )

    return failures, warnings


def main() -> int:
    repo_root = sys.argv[1] if len(sys.argv) > 1 else "."
    plugin_pattern = os.path.join(repo_root, "plugins", "*", "skills", "*", "SKILL.md")
    guide_path = os.path.join(repo_root, "guide", "SKILL.md")

    skill_files = sorted(glob.glob(plugin_pattern))
    if os.path.exists(guide_path):
        skill_files.append(guide_path)

    if not skill_files:
        print(f"check_description_quality: no SKILL.md files found under {repo_root}")
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
        f"\ncheck_description_quality: {total} skill(s) checked, "
        f"{len(all_failures)} failure(s), {len(all_warnings)} warning(s)"
    )

    return 1 if all_failures else 0


if __name__ == "__main__":
    sys.exit(main())
