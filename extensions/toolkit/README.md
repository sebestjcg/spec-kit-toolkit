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

## Install

From a published release:

```bash
specify extension add --from <release-zip-url>
```

From a local clone (development):

```bash
specify extension add --dev ./extensions/toolkit
```

## Why an extension (not a preset)?

Extensions *add* new namespaced commands; presets *override* existing core
commands. These six commands have no upstream counterpart, so an extension is
the correct vehicle and none of this repo's semantic-delta / regenerate
machinery (used by the `claude-ask-questions` preset to track core changes) is
needed.

## License

MIT — see [LICENSE](./LICENSE).
