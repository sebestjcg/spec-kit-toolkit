# spec-kit-toolkit

Tooling and presets for [Spec Kit](https://github.com/github/spec-kit).

## Presets

| Preset | What it does |
| ------ | ------------ |
| [`claude-ask-questions`](./presets/claude-ask-questions) | Renders `/speckit.clarify` and `/speckit.checklist` questions with Claude Code's native `AskUserQuestion` picker (recommendation + reasoning on every prompt). |

### Design principle: presets that survive core updates

Presets here avoid the trap of shipping a frozen full copy of a core command
(the default `replace` strategy), which silently drops upstream improvements
whenever spec-kit core is updated.

Instead, each command override keeps only a small **semantic delta** and a
generator that re-applies that delta onto the **current** core command via
`claude -p`. Upgrading core becomes "re-run the generator and commit," not
"hand-merge a diverged file." See
[`presets/claude-ask-questions/README.md`](./presets/claude-ask-questions/README.md)
for the full mechanism.
