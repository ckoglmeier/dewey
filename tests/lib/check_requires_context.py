#!/usr/bin/env python3
"""Validate a single SKILL.md's context declarations.

Usage: check_requires_context.py <skill_md> <plugin_dir> <plugin_name>

Exits 0 if valid (or no requires-context declared), non-zero with a clear
message on failure.

Validates:
- Every declared requires-context id resolves to a context entry in some
  plugin's plugin.json
- Every declared id also appears as a literal string in the skill body
  (catches frontmatter/body drift)
- Every extends-context target resolves
- The skill's surfaces are a subset of each required context's surfaces
- Total declared context size is within bounds (300KB hard limit unless
  every involved entry is allow-large-context: true; 80KB warn threshold
  prints a warning)
"""
from __future__ import annotations
import json
import os
import re
import sys
import glob
from typing import Optional

WARN = 80 * 1024
FAIL = 300 * 1024


def parse_requires_context(fm_text: str, skill_md: str) -> list[str]:
    """Extract requires-context: list from a SKILL.md frontmatter block.

    Only supports the YAML block form (one '- id' per line). Inline form
    is rejected because the embedded YAML in our skills always uses block.
    """
    required: list[str] = []
    in_block = False
    for line in fm_text.splitlines():
        if re.match(r"^requires-context\s*:", line):
            rest = line.split(":", 1)[1].strip()
            if rest:
                sys.exit(
                    f"{skill_md}: requires-context must use block form "
                    f"(one '- id' per line), not inline"
                )
            in_block = True
            continue
        if in_block:
            m = re.match(r"^\s*-\s*(.+?)\s*$", line)
            if m:
                required.append(m.group(1).strip())
            elif line and not line.startswith((" ", "\t", "-")):
                in_block = False
    return required


def parse_extends_context(fm_text: str, skill_md: str) -> Optional[str]:
    """Extract a single extends-context: value from frontmatter."""
    found: Optional[str] = None
    for line in fm_text.splitlines():
        m = re.match(r"^extends-context\s*:\s*(.+?)\s*$", line)
        if not m:
            continue
        value = m.group(1).strip().strip("\"'")
        if not value:
            sys.exit(f"{skill_md}: extends-context must name a context id")
        if found is not None:
            sys.exit(f"{skill_md}: extends-context declared more than once")
        found = value
    return found


def collect_context_index() -> dict[str, dict]:
    """Build {id: {plugin, plugin_dir, surfaces, path, allow_large}} from all plugins."""
    index: dict[str, dict] = {}
    for pj in glob.glob("plugins/*/.claude-plugin/plugin.json"):
        d = json.load(open(pj))
        pname = d["name"]
        pdir = os.path.dirname(os.path.dirname(pj))
        plugin_surfaces = d.get("surfaces") or ["claude-code"]
        for entry in d.get("context") or []:
            index[entry["id"]] = {
                "plugin": pname,
                "plugin_dir": pdir,
                "surfaces": entry.get("surfaces") or plugin_surfaces,
                "path": entry["path"],
                "allow_large": bool(entry.get("allow-large-context")),
            }
    return index


def files_under(root: str):
    if os.path.isfile(root):
        yield root
        return
    for dirpath, _, filenames in os.walk(root):
        for fn in filenames:
            yield os.path.join(dirpath, fn)


def main() -> int:
    if len(sys.argv) != 4:
        print("usage: check_requires_context.py <skill_md> <plugin_dir> <plugin_name>", file=sys.stderr)
        return 2

    skill_md, plugin_dir, plugin_name = sys.argv[1], sys.argv[2], sys.argv[3]

    text = open(skill_md).read()
    m = re.match(r"^---\n(.*?)\n---\n(.*)", text, re.DOTALL)
    if not m:
        return 0  # No frontmatter — nothing to validate

    fm_text, body = m.group(1), m.group(2)
    required = parse_requires_context(fm_text, skill_md)
    extends_context = parse_extends_context(fm_text, skill_md)
    if not required and not extends_context:
        return 0

    index = collect_context_index()

    plugin_pj = os.path.join(plugin_dir, ".claude-plugin", "plugin.json")
    plugin_meta = json.load(open(plugin_pj))
    skill_surfaces = set(plugin_meta.get("surfaces") or ["claude-code"])

    total_size = 0
    all_allow_large = True

    if extends_context:
        if extends_context not in index:
            sys.exit(f"{skill_md}: extends-context id does not resolve: {extends_context}")
        ctx_surfaces = set(index[extends_context]["surfaces"])
        if not skill_surfaces.issubset(ctx_surfaces):
            missing = skill_surfaces - ctx_surfaces
            sys.exit(
                f"{skill_md}: extends {extends_context} but its surfaces "
                f"{sorted(ctx_surfaces)} do not cover skill surfaces {sorted(missing)}"
            )

    for cid in required:
        if cid not in index:
            sys.exit(f"{skill_md}: requires-context id does not resolve: {cid}")
        if cid not in body:
            sys.exit(
                f"{skill_md}: declares requires-context: {cid} but it does not "
                f"appear as a literal in the skill body (frontmatter/body drift)"
            )
        ctx_surfaces = set(index[cid]["surfaces"])
        if not skill_surfaces.issubset(ctx_surfaces):
            missing = skill_surfaces - ctx_surfaces
            sys.exit(
                f"{skill_md}: requires {cid} but its surfaces "
                f"{sorted(ctx_surfaces)} do not cover skill surfaces {sorted(missing)}"
            )
        full = os.path.join(index[cid]["plugin_dir"], index[cid]["path"])
        if not index[cid]["allow_large"]:
            all_allow_large = False
        for f in files_under(full):
            total_size += os.path.getsize(f)

    if total_size > FAIL and not all_allow_large:
        sys.exit(
            f"{skill_md}: total declared context size {total_size} exceeds "
            f"300KB; mark all entries allow-large-context: true to permit"
        )
    if total_size > WARN:
        print(
            f"{skill_md}: warning: total declared context size {total_size} "
            f"exceeds 80KB; consider splitting or narrowing loaded context",
            file=sys.stderr,
        )

    return 0


if __name__ == "__main__":
    sys.exit(main())
