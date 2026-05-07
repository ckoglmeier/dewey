#!/usr/bin/env python3
"""Live-validate one external marketplace plugin entry.

Usage: validate_external_entry.py '<entry_json>'

Performs network I/O to confirm the entry actually resolves to a valid
Classroom plugin. Catches the failure mode that schema-only lint can't see:
the manifest is well-formed but the upstream is missing, the plugin.json
isn't where we expect, or the name doesn't match what we registered.

Per source type:
- github: shallow clone, confirm the upstream is either a single plugin
          (.claude-plugin/plugin.json with matching name) OR a marketplace
          (.claude-plugin/marketplace.json with a plugins[] entry of the
          expected name). The marketplace layout is what Anthropic's
          official github sources use.
- url:    GET the URL (must be a tarball), extract, same dual-layout check
- npm:    npm view + npm pack the package; confirm the unpacked tree has
          a matching plugin.json (npm packages are typically single plugins)

Exits 0 on success. Non-zero with a clear message on any failure.

Requires git + curl on PATH for github/url. Requires npm for npm sources.
Skips an entry's validation cleanly with exit 77 (skip) if a required tool
is missing, so partial validation still runs in environments without npm.
"""
from __future__ import annotations
import json
import os
import shutil
import subprocess
import sys
import tarfile
import tempfile
import urllib.request


def die(msg: str) -> "NoReturn":
    print(msg, file=sys.stderr)
    sys.exit(1)


def skip(msg: str) -> "NoReturn":
    print(f"SKIP: {msg}", file=sys.stderr)
    sys.exit(77)


def have(cmd: str) -> bool:
    return shutil.which(cmd) is not None


def confirm_plugin_resolves(root: str, expected_name: str, entry_name: str) -> None:
    """Confirm the upstream contains a plugin named expected_name.

    Two layouts are accepted (matches what Claude Code does):
    1. The upstream is a single plugin: .claude-plugin/plugin.json at root,
       with name matching expected_name.
    2. The upstream is a marketplace: .claude-plugin/marketplace.json at root,
       with a plugins[] entry whose name matches expected_name.

    Layout (2) is what Anthropic's official github-source entries use
    (e.g. browserbase/agent-browse → marketplace with 'browse' and
    'functions' plugins). Layout (1) is the simpler case for a repo that
    is itself one plugin.
    """
    pj = os.path.join(root, ".claude-plugin", "plugin.json")
    mj = os.path.join(root, ".claude-plugin", "marketplace.json")

    if os.path.exists(pj):
        try:
            meta = json.load(open(pj))
        except Exception as e:
            die(f"{entry_name}: plugin.json is not valid JSON: {e}")
        if meta.get("name") != expected_name:
            die(
                f"{entry_name}: marketplace entry name {expected_name!r} does not match "
                f"the upstream plugin.json name {meta.get('name')!r}"
            )
        return

    if os.path.exists(mj):
        try:
            up = json.load(open(mj))
        except Exception as e:
            die(f"{entry_name}: upstream marketplace.json is not valid JSON: {e}")
        plugins = up.get("plugins") or []
        if not any(p.get("name") == expected_name for p in plugins):
            available = sorted(p.get("name", "<unnamed>") for p in plugins)
            die(
                f"{entry_name}: upstream is a marketplace at {mj} but it has no "
                f"plugin named {expected_name!r}. Available: {available}"
            )
        return

    die(
        f"{entry_name}: external entry resolves but no .claude-plugin/plugin.json "
        f"or .claude-plugin/marketplace.json found at the upstream root. "
        f"The marketplace entry is broken."
    )


def validate_github(entry: dict, tmp: str) -> None:
    name = entry["name"]
    src = entry["source"]
    repo = src.get("repo")
    if not repo:
        die(f"{name}: github source missing 'repo' field")
    if not have("git"):
        skip(f"{name}: git not installed; cannot validate github source live")

    url = f"https://github.com/{repo}.git"
    target = os.path.join(tmp, "checkout")
    try:
        subprocess.run(
            ["git", "clone", "--depth=1", "--quiet", url, target],
            check=True,
            timeout=60,
            stderr=subprocess.PIPE,
        )
    except subprocess.CalledProcessError as e:
        msg = e.stderr.decode("utf-8", "replace").strip()
        die(f"{name}: git clone of {url} failed: {msg or 'see git output'}")
    except subprocess.TimeoutExpired:
        die(f"{name}: git clone of {url} timed out after 60s")

    confirm_plugin_resolves(target, name, name)


def validate_url(entry: dict, tmp: str) -> None:
    name = entry["name"]
    src = entry["source"]
    url = src.get("url")
    if not url:
        die(f"{name}: url source missing 'url' field")

    archive = os.path.join(tmp, "archive.tar.gz")
    try:
        urllib.request.urlretrieve(url, archive)
    except Exception as e:
        die(f"{name}: download of {url} failed: {e}")

    extracted = os.path.join(tmp, "extracted")
    os.makedirs(extracted, exist_ok=True)
    try:
        with tarfile.open(archive) as tf:
            tf.extractall(extracted)
    except Exception as e:
        die(f"{name}: tarball at {url} could not be extracted: {e}")

    # Look for either .claude-plugin/plugin.json OR .claude-plugin/marketplace.json,
    # at the root or one level down (typical github tarball wraps everything in a
    # single top-level directory).
    candidates = [extracted] + [
        os.path.join(extracted, d)
        for d in os.listdir(extracted)
        if os.path.isdir(os.path.join(extracted, d))
    ]
    for c in candidates:
        if os.path.exists(os.path.join(c, ".claude-plugin", "plugin.json")) or \
           os.path.exists(os.path.join(c, ".claude-plugin", "marketplace.json")):
            confirm_plugin_resolves(c, name, name)
            return
    die(
        f"{name}: no .claude-plugin/plugin.json or marketplace.json found in "
        f"extracted tarball from {url}"
    )


def validate_npm(entry: dict, tmp: str) -> None:
    name = entry["name"]
    src = entry["source"]
    pkg = src.get("package")
    if not pkg:
        die(f"{name}: npm source missing 'package' field")
    if not have("npm"):
        skip(f"{name}: npm not installed; cannot validate npm source live")

    try:
        result = subprocess.run(
            ["npm", "view", pkg, "name"],
            check=True,
            timeout=30,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except subprocess.CalledProcessError as e:
        msg = e.stderr.decode("utf-8", "replace").strip()
        die(f"{name}: npm package {pkg} not found or unreachable: {msg or 'see npm output'}")
    except subprocess.TimeoutExpired:
        die(f"{name}: npm view of {pkg} timed out after 30s")

    published_name = result.stdout.decode("utf-8").strip()
    if not published_name:
        die(f"{name}: npm view returned no name for package {pkg}")

    # Pull the package contents to confirm plugin.json shape
    try:
        subprocess.run(
            ["npm", "pack", pkg, "--silent", "--pack-destination", tmp],
            check=True,
            timeout=60,
            stderr=subprocess.PIPE,
        )
    except subprocess.CalledProcessError as e:
        msg = e.stderr.decode("utf-8", "replace").strip()
        die(f"{name}: npm pack of {pkg} failed: {msg}")
    except subprocess.TimeoutExpired:
        die(f"{name}: npm pack of {pkg} timed out after 60s")

    tgz = next(
        (os.path.join(tmp, f) for f in os.listdir(tmp) if f.endswith(".tgz")), None
    )
    if not tgz:
        die(f"{name}: npm pack produced no .tgz")

    extracted = os.path.join(tmp, "pkg-extracted")
    os.makedirs(extracted, exist_ok=True)
    with tarfile.open(tgz) as tf:
        tf.extractall(extracted)
    # npm packs into a "package/" subdir
    pkg_root = os.path.join(extracted, "package")
    confirm_plugin_resolves(pkg_root, name, name)


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: validate_external_entry.py '<entry_json>'", file=sys.stderr)
        return 2

    try:
        entry = json.loads(sys.argv[1])
    except json.JSONDecodeError as e:
        die(f"argv[1] is not valid JSON: {e}")

    src = entry.get("source")
    if not isinstance(src, dict):
        die(
            f"{entry.get('name', '<unknown>')}: source is not an object — "
            f"this entry isn't external (no live validation needed)"
        )

    src_type = src.get("source")
    handlers = {
        "github": validate_github,
        "url": validate_url,
        "npm": validate_npm,
    }
    handler = handlers.get(src_type)
    if not handler:
        die(
            f"{entry.get('name')}: source type {src_type!r} is not supported by live "
            f"validation (accepted: {sorted(handlers)})"
        )

    with tempfile.TemporaryDirectory() as tmp:
        handler(entry, tmp)

    return 0


if __name__ == "__main__":
    sys.exit(main())
