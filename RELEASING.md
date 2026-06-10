# Releasing Dewey

Follow this checklist for every release. Skipping a step risks shipping a broken or unverified installer to end users.

## Checklist

### 1. Bump the version in marketplace.json

Edit `.claude-plugin/marketplace.json` and increment `metadata.version` following semver:

- **patch** (`2.0.0 → 2.0.1`): bug fixes, documentation, test changes
- **minor** (`2.0.0 → 2.1.0`): new features, new in-tree plugins/skills, backwards-compatible changes
- **major** (`2.0.0 → 3.0.0`): breaking changes to install conventions, env vars, or skill interfaces

Commit the bump on main (or merge a release branch to main first):

```bash
git add .claude-plugin/marketplace.json
git commit -m "chore: bump version to vX.Y.Z"
```

### 2. Run the full test suite

```bash
bash tests/run.sh
```

All tests must pass. Do not proceed if any are red.

### 3. Create and push the git tag

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

The tag must exist in the remote repo before `gh release create` can reference it.

### 4. Build the release artifacts

```bash
bash scripts/build-release.sh vX.Y.Z
```

This produces `dist/dewey-vX.Y.Z.tar.gz` and `dist/dewey-vX.Y.Z.tar.gz.sha256`.

### 5. Create the GitHub release

Copy the `gh release create` command printed by the previous step and run it:

```bash
gh release create vX.Y.Z \
  dist/dewey-vX.Y.Z.tar.gz \
  dist/dewey-vX.Y.Z.tar.gz.sha256 \
  --generate-notes
```

Both files must be attached. The installer fetches the `.sha256` asset from the release to verify the tarball — if it is missing, the installer falls back to the GitHub archive URL and skips verification.

### 6. Verify a clean install from the new release

In a fresh sandbox (or a clean VM), run the installer without any env overrides:

```bash
curl -fsSL https://raw.githubusercontent.com/ckoglmeier/dewey/main/install.sh | bash
```

Confirm:

- The installer prints "Pinning to release vX.Y.Z".
- The installer prints "Verifying tarball checksum" and completes without error.
- `~/.claude/dewey/.claude-plugin/marketplace.json` contains `"version": "X.Y.Z"`.
- `~/.claude/dewey-refresh.sh` exists and is executable.

If any check fails, delete the GitHub release (`gh release delete vX.Y.Z --yes`), fix the issue, and restart from step 1.

## Notes

- **dist/** is gitignored. Build artifacts are never committed to the repo.
- The `scripts/build-release.sh` script does not push, tag, or create releases — it only builds local artifacts. All network operations are your responsibility.
- After creating a release, the next `bash tests/run.sh` run exercises the offline suite only. A post-release clean-VM test is the definitive verification.
