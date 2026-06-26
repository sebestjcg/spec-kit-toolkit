# Changelog

## 1.0.0 - 2026-06-26

- Initial release.
- Overrides `speckit.clarify` to use Claude Code's `AskUserQuestion` picker
  instead of Markdown-table rendering, with a recommended option + reasoning and
  a "Short" free-form escape hatch.
- Overrides `speckit.checklist` to use `AskUserQuestion` for the
  Option / Candidate / Why-It-Matters selection, with a "Custom" escape hatch.
- Built as a **regenerate-on-demand** preset: the only durable artifact is the
  semantic delta in `delta/`; the shipped `commands/` are produced by merging
  that delta into the current core command via `claude -p` (`scripts/generate.sh`),
  so the override survives spec-kit core updates instead of freezing a full copy.
