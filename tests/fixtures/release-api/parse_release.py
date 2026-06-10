#!/usr/bin/env python3
"""
parse_release.py <json-file>

Parse a GitHub releases-API JSON response (canned fixture) and print the
fields that resolve_release() in install.sh would extract. Used by layer-06
tests to unit-test the parsing logic without network access.

Output (one key=value per line):
  tag=<tag_name>
  asset_url=<browser_download_url of dewey-<tag>.tar.gz, or empty>
  sha256_url=<browser_download_url of dewey-<tag>.tar.gz.sha256, or empty>

Exit codes:
  0  success (tag found; assets may or may not be present)
  1  parse error or no tag_name
"""
import json, sys

if len(sys.argv) < 2:
    print("usage: parse_release.py <json-file>", file=sys.stderr)
    sys.exit(1)

try:
    with open(sys.argv[1]) as f:
        d = json.load(f)
except Exception as e:
    print(f"error: {e}", file=sys.stderr)
    sys.exit(1)

tag = d.get("tag_name", "")
if not tag:
    print("error: no tag_name in response", file=sys.stderr)
    sys.exit(1)

asset_name = f"dewey-{tag}.tar.gz"
sha256_name = f"dewey-{tag}.tar.gz.sha256"

asset_url = ""
sha256_url = ""
for a in d.get("assets", []):
    if a.get("name") == asset_name:
        asset_url = a.get("browser_download_url", "")
    if a.get("name") == sha256_name:
        sha256_url = a.get("browser_download_url", "")

print(f"tag={tag}")
print(f"asset_url={asset_url}")
print(f"sha256_url={sha256_url}")
