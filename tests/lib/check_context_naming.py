#!/usr/bin/env python3
"""Validate the v1 context-bundle naming convention for a single plugin.

Usage: check_context_naming.py <plugin_dir>

Convention: every context entry's primary `path` is a file named `context.md`
(or a directory — the directory case is for bundles that don't have a single
canonical entry yet, which is allowed but discouraged).

Exits 0 if the plugin has no context array, or every entry follows the
convention. Non-zero with a clear message otherwise.
"""
import json
import os
import sys


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: check_context_naming.py <plugin_dir>", file=sys.stderr)
        return 2

    plugin_dir = sys.argv[1]
    manifest = os.path.join(plugin_dir, ".claude-plugin", "plugin.json")
    if not os.path.exists(manifest):
        return 0

    p = json.load(open(manifest))
    ctx = p.get("context") or []
    for entry in ctx:
        cid = entry.get("id", "<unknown>")
        path = entry.get("path", "")
        base = os.path.basename(path)
        full = os.path.join(plugin_dir, path)
        if base == "context.md":
            continue
        if os.path.isdir(full):
            continue
        sys.exit(
            f"context entry {cid!r} primary file is {base!r}; "
            f"convention is context.md (see docs/canonical-context.md)"
        )
    return 0


if __name__ == "__main__":
    sys.exit(main())
