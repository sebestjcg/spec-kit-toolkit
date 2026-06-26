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

`commands/` is **gitignored** (generated output). The delta files are the only
committed artifact.

## Installation

`generate.sh` must run before every `specify preset add` to produce the
`commands/` files. `install.sh` chains both steps:

```bash
# From a spec-kit project root (auto-detects core):
presets/claude-ask-questions/install.sh

# Or point explicitly at core:
presets/claude-ask-questions/install.sh --core-dir /path/to/.specify/templates/commands
```

Requires the `claude` CLI on `PATH`.

Verify with:

```bash
specify preset list
ls .claude/commands/speckit.clarify.md .claude/commands/speckit.checklist.md
```

Remove with:

```bash
specify preset remove claude-ask-questions
```

## Refreshing against a new core version

After upgrading spec-kit core, re-run the same install command — it regenerates
the merged commands and re-registers them:

```bash
presets/claude-ask-questions/install.sh --core-dir /path/to/.specify/templates/commands
```

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
