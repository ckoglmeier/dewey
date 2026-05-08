# Publishing a Dewey plugin to npm

Any Dewey plugin can be distributed as an npm package in addition to (or instead of) the default tarball/directory delivery. Publishing to npm gives you versioned, pinnable releases that teams can install without pointing at a git repository.

Claude Code's plugin system already understands npm sources — Dewey just defines the expected layout.

## Package layout

```
dewey-plugin-<name>/
├── package.json
├── .claude-plugin/
│   └── plugin.json        ← same schema as in-tree plugins
└── skills/
    └── <skill-name>/
        └── SKILL.md
```

The npm package is a thin wrapper around the standard Dewey plugin directory structure. No additional manifest file is needed — `plugin.json` is the source of truth.

### package.json

```json
{
  "name": "@myorg/dewey-plugin-meeting-prep",
  "version": "1.2.0",
  "description": "Meeting prep skills for Dewey",
  "files": [".claude-plugin", "skills"],
  "license": "MIT"
}
```

The `files` array is important: it restricts what npm publishes to just the plugin content, skipping any local development files.

### plugin.json

Identical to an in-tree plugin's manifest:

```json
{
  "name": "meeting-prep",
  "description": "Prepare for meetings: agendas, pre-reads, follow-up briefs.",
  "version": "1.2.0",
  "author": {
    "name": "Your Name",
    "contact": "@yourhandle"
  }
}
```

The `name` field must match the marketplace entry name and the directory name inside `skills/`.

## Adding to marketplace.json

Reference the package by its npm name. Two forms:

**Floating (always latest):**
```json
{
  "name": "meeting-prep",
  "source": { "source": "npm", "package": "@myorg/dewey-plugin-meeting-prep" },
  "description": "Prepare for meetings: agendas, pre-reads, follow-up briefs.",
  "category": "operations",
  "tags": ["meetings", "async"]
}
```

**Pinned (recommended for production):**
```json
{
  "name": "meeting-prep",
  "source": { "source": "npm", "package": "@myorg/dewey-plugin-meeting-prep", "version": "1.2.0" },
  "description": "Prepare for meetings: agendas, pre-reads, follow-up briefs.",
  "category": "operations",
  "tags": ["meetings", "async"]
}
```

The test suite validates that every `npm` source entry has a `package` field (Layer 3b).

## Publishing

```bash
cd dewey-plugin-meeting-prep
npm publish --access public
```

For private registries, set `"publishConfig": { "registry": "https://npm.pkg.github.com" }` in package.json.

## Version discipline

- Bump `version` in both `package.json` and `plugin.json` together (they should match)
- Tag releases: `git tag v1.2.0 && git push --tags`
- Pin the version in marketplace.json once the plugin is stable — floating `latest` can break teams on a new session

## Comparison with other source types

| Source type | Best for |
|---|---|
| `./plugins/<name>` | In-tree plugins (this repo owns the skill) |
| `npm` | Versioned, team-distributed skills via a registry |
| `git-subdir` | External repo skills (blocked by Claude Code validator bug — see CLAUDE.md) |
| `github` | Public GitHub repos with pinned SHA |
| `url` | Arbitrary tarballs |

npm is the right choice when you want semantic versioning, a CHANGELOG, and `npm install`-style reproducibility for your skill distribution.
