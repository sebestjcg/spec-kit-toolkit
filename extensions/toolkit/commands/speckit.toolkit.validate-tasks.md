---
description: "Ensure tasks.md contains explicit red-green-refactor task steps and Playwright end-to-end verification entries for each feature."
scripts:
  sh: ../../scripts/bash/check-prerequisites.sh --json
  ps: ../../scripts/powershell/check-prerequisites.ps1 -Json
---

# Validate Tasks (tasks.md)

Enforce the same two mandates as `validate-testing`, but against `tasks.md` as
**concrete, actionable task entries**. Where they are absent, add explicit
red-green-refactor task steps and Playwright end-to-end-verification task entries
**in place**, then report the changes.

1. Implementing features using **Domain-Driven Design (DDD)** principles,
   following a **red-green-refactor** test-driven-development workflow.
2. After each feature is implemented, using **Playwright** to verify the feature
   works correctly **end-to-end**.

## User Input

```text
$ARGUMENTS
```

`$ARGUMENTS` is an optional path override (a `tasks.md` path or feature
directory). When empty, resolve the feature automatically.

## Prerequisites

1. Run `.specify/scripts/bash/check-prerequisites.sh --json` and parse
   `FEATURE_DIR`. On failure, use the `$ARGUMENTS` override.
2. Read `FEATURE_DIR/tasks.md`. If it is missing, report and stop.

## Audit

For each feature / feature-group of tasks in `tasks.md`, check that it contains:

- Explicit **red-green-refactor** TDD steps — a "write the failing test" step
  before the implementation step, and a refactor step after — framed in DDD
  terms (domain model / aggregates / ubiquitous language where applicable).
- An explicit **Playwright end-to-end verification** task that runs after the
  feature's implementation tasks.

## Apply

- For each feature missing these, insert the missing task entries in the correct
  position, **matching whichever style `tasks.md` already uses** — checkbox OR
  numbered (e.g. `T001`-style). Do not mix styles within a file.
  - Checkbox-style examples:
    - `- [ ] Write a failing test for <behavior> (red) before implementing.`
    - `- [ ] Implement the minimal code to make the test pass (green).`
    - `- [ ] Refactor with tests green; keep the domain model clean (refactor).`
    - `- [ ] Verify <feature> end-to-end with Playwright.`
  - Numbered-style examples (use when `tasks.md` uses `T001` entries):
    - `T042 Write a failing test for <behavior> (red) before implementing.`
    - `T043 Implement the minimal code to make the test pass (green).`
    - `T044 Refactor with tests green; keep the domain model clean (refactor).`
    - `T045 Verify <feature> end-to-end with Playwright.`
- Do not duplicate steps that already exist. Preserve existing tasks, numbering,
  and formatting. Edit `tasks.md` **in place**.

## Report

List the task entries added, grouped by the feature they were added to. If every
feature already had both, say so and make no edits.
