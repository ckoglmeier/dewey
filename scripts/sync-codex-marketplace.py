#!/usr/bin/env python3
"""Generate .agents/plugins/marketplace.json from .claude-plugin/marketplace.json.

OpenAI Codex (0.149+) has a native plugin marketplace. It can read Dewey's
.claude-plugin/marketplace.json as a legacy-compatible manifest, but the
standard location (Agent Plugins 1.0) is .agents/plugins/marketplace.json, and
Codex prefers it when both exist. This script keeps the two in sync so the
Claude manifest stays the single source of truth.

Usage:
    python3 scripts/sync-codex-marketplace.py           # (re)write the Codex manifest
    python3 scripts/sync-codex-marketplace.py --check   # exit 1 if it is stale (used by Layer 3)

Only in-tree plugins (relative "./plugins/<name>" sources) are mirrored; external
Claude Code source types (github, npm, ...) have no Codex equivalent yet.
"""
from __future__ import annotations
import json
import os
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(REPO_ROOT, ".claude-plugin", "marketplace.json")
DST = os.path.join(REPO_ROOT, ".agents", "plugins", "marketplace.json")


def build() -> str:
    with open(SRC, encoding="utf-8") as f:
        m = json.load(f)
    display = m["name"].replace("-", " ").title()
    out = {"name": m["name"], "interface": {"displayName": display}, "plugins": []}
    for p in m["plugins"]:
        src = p["source"]
        if not (isinstance(src, str) and src.startswith("./")):
            continue
        entry = {"name": p["name"], "source": {"source": "local", "path": src}}
        if p.get("category"):
            entry["category"] = p["category"]
        out["plugins"].append(entry)
    return json.dumps(out, indent=2) + "\n"


def main() -> int:
    text = build()
    if "--check" in sys.argv:
        current = ""
        if os.path.exists(DST):
            with open(DST, encoding="utf-8") as f:
                current = f.read()
        if current != text:
            print(".agents/plugins/marketplace.json is stale — run: python3 scripts/sync-codex-marketplace.py")
            return 1
        print("ok: .agents/plugins/marketplace.json matches .claude-plugin/marketplace.json")
        return 0
    os.makedirs(os.path.dirname(DST), exist_ok=True)
    with open(DST, "w", encoding="utf-8") as f:
        f.write(text)
    print(f"wrote {os.path.relpath(DST, REPO_ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
