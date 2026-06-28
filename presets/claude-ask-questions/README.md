# Claude AskUserQuestion Preset

A [Spec Kit](https://github.com/github/spec-kit) preset that replaces the
Markdown-table question rendering in `/speckit.clarify` and `/speckit.checklist`
with [Claude Code's](https://claude.com/claude-code) native `AskUserQuestion`
structured picker — with a recommended option and reasoning on every prompt.

## What it changes

| Command              | Behavior                                                                                                           |
| -------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `/speckit.clarify`   | Asks up to 5 clarification questions via `AskUserQuestion`, each with a pre-computed recommendation and reasoning.  |
| `/speckit.checklist` | Presents the Option / Candidate / Why-It-Matters selection via `AskUserQuestion` instead of a Markdown table.       |

Only the **question-rendering** blocks are touched. The ambiguity taxonomy, the
5-question cap, the spec-integration rules, and the pre/post-execution hook
sections come straight from upstream core — see [`delta/`](./delta/) for the
exact, and only, edits this preset makes.

## Why this preset is built the way it is

A naive preset ships a **full copy** of each command with the default `replace`
strategy. That copy freezes the command at one point in time: when spec-kit core
later updates `speckit.clarify` / `speckit.checklist` (new sections, bug fixes),
the frozen copy keeps overriding and silently drops every core improvement.

This preset avoids that. The durable source of truth is a tiny **semantic delta**
([`delta/*.delta.md`](./delta/)) describing *only* the AskUserQuestion change.
The shipped command files under [`commands/`](./commands/) are **generated** by
re-applying that delta onto the **current** core command via `claude -p`:

```
delta/speckit.clarify.delta.md  ┐
current core speckit.clarify.md ┼─►  claude -p  ─►  commands/speckit.clarify.md
                                ┘
```

So when core is updated, you don't hand-merge — you regenerate.

`commands/` are committed snapshots, regenerated and recommitted on each release.
The delta files are the durable source of truth.

## Installation

```bash
specify preset add --from https://github.com/sebestjcg/spec-kit-toolkit/releases/download/v0.7.0/spec-kit-toolkit-preset-0.8.17.zip
```

The zip filename reflects the spec-kit version the commands were generated against.
Check the [releases page](https://github.com/sebestjcg/spec-kit-toolkit/releases) for the latest tag and filename.

Or from a local clone:

```bash
specify preset add --dev ./presets/claude-ask-questions
```

## Releasing a new version

After upgrading spec-kit, regenerate `commands/`, package, and publish:

```bash
# 1. Regenerate commands/ against current spec-kit (also stamps preset.yml version)
presets/claude-ask-questions/scripts/generate.sh

# 2. Commit and tag
git add presets/claude-ask-questions/
git commit -m "chore: regenerate commands against spec-kit vX.Y.Z"
git tag vX.Y.Z && git push --tags

# 3. Build zip and publish GitHub Release (auto-detects tag from HEAD)
scripts/package.sh

# 4. Update the --from URL in this README with the new tag
```

Requires `specify` and `claude` CLIs on `PATH`. Pass `--core-dir` to
`generate.sh` to skip the `specify init` step and point directly at an existing
project's `.claude/skills/` directory.

## Requirements

- [Spec Kit](https://github.com/github/spec-kit) `>= 0.6.0`
- [Claude Code](https://claude.com/claude-code) — `AskUserQuestion` is
  Claude-specific. Other agents fall back to their default behavior.

## Compatibility

- ⚠️ Conflicts with any other preset that also overrides `speckit.clarify` or
  `speckit.checklist`. Only the highest-priority preset wins for a given command.
- ❌ Not useful for non-Claude agents — they don't expose `AskUserQuestion`.

## Attribution

The AskUserQuestion rendering rules originate from the community preset
[`spec-kit-preset-claude-ask-questions`](https://github.com/0xrafasec/spec-kit-preset-claude-ask-questions)
by 0xrafasec (MIT). This package re-expresses the same behavior as a
regenerate-on-demand semantic delta so it survives core updates.

## License

[MIT](./LICENSE)
