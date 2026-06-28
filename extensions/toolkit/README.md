# Spec Kit Toolkit Extension

A [Spec Kit](https://github.com/github/spec-kit) extension (id `toolkit`) that
adds six namespaced workflow commands for spec-driven development. These are
**net-new** commands — they do not override any core command — so the extension
ships them as plain static markdown with no delta/regenerate machinery, no
scripts, no config, and no hooks.

## Commands

| Command | What it does |
| ------- | ------------ |
| `/speckit.toolkit.tick-checklist` | Checks off review/acceptance checklist items the feature `spec.md` demonstrably satisfies; leaves unmet items unchecked. Edits in place. |
| `/speckit.toolkit.resolve-checklist` | Resolves unchecked items from a requirements-docs path, then the codebase, then by asking via `AskUserQuestion` in batches of 5. Checks off resolved items only. |
| `/speckit.toolkit.validate-plan` | Audits `plan.md` + implementation-detail files and inserts missing cross-references from implementation steps to the relevant detail sections. |
| `/speckit.toolkit.validate-testing` | Ensures `plan.md` explicitly mandates DDD red-green-refactor TDD and post-feature Playwright end-to-end verification. |
| `/speckit.toolkit.validate-tasks` | Ensures `tasks.md` has explicit red-green-refactor task steps and Playwright end-to-end verification entries per feature. |
| `/speckit.toolkit.research` | Runs a Path A/Path B decision-gate research pass: pins versions into `research.md` and fans out parallel, version-pinned research subagents. |

All file-mutating commands edit **in place** and print a concise report of what
changed. Each command resolves the active feature via core spec-kit's
`check-prerequisites.sh --json` and accepts an optional path override in its
arguments.

## Installation

```bash
specify extension add toolkit --from https://github.com/sebestjcg/spec-kit-toolkit/releases/download/vX.Y.Z/spec-kit-toolkit-extension-X.Y.Z.zip
```

The zip filename reflects the spec-kit version stamped at build time; the release
tag is independent of it. Check the [releases page](https://github.com/sebestjcg/spec-kit-toolkit/releases)
for the latest tag and filename.

Or from a local clone (development):

```bash
specify extension add --dev ./extensions/toolkit
```

Run `specify extension list` afterward to confirm `toolkit` is registered. The
six commands then appear to your agent as `/speckit.toolkit.tick-checklist`,
`/speckit.toolkit.resolve-checklist`, and so on.

## Releasing a new version

The extension ships static command files, so there is nothing to regenerate —
just stamp the version, tag, and publish. `scripts/package.sh` stamps
`extension.yml` with your installed spec-kit version and builds
`spec-kit-toolkit-extension-<version>.zip` with `extension.yml` at the zip root (so
`specify extension add <id> --from <url>` works on the release asset).

```bash
# 1. Stamp extension.yml with the current spec-kit version and build the zip (no release yet)
scripts/package.sh --only toolkit --no-release

# 2. Commit the version bump and tag
git add extensions/toolkit/extension.yml
git commit -m "chore: stamp toolkit version against spec-kit vX.Y.Z"
git tag vX.Y.Z && git push --tags

# 3. Build and publish the GitHub Release (auto-detects the tag from HEAD)
scripts/package.sh --only toolkit

# 4. Update the install URL above with the new tag and filename
```

`--only toolkit` scopes packaging to this extension, so other presets/extensions
in the repo are left untouched.

## Requirements

- [Spec Kit](https://github.com/github/spec-kit) `>= 0.6.0`
- For releasing: the `specify` and `gh` CLIs on `PATH` — `specify` stamps the
  version, `gh` creates the GitHub Release. Pass `--no-release` to build the zip
  without publishing.

## Why an extension (not a preset)?

Extensions *add* new namespaced commands; presets *override* existing core
commands. These six commands have no upstream counterpart, so an extension is
the correct vehicle and none of this repo's semantic-delta / regenerate
machinery (used by the `claude-ask-questions` preset to track core changes) is
needed.

## License

MIT — see [LICENSE](./LICENSE).
