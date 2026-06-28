---
description: "Ensure plan.md explicitly mandates DDD red-green-refactor TDD and post-feature Playwright end-to-end verification."
scripts:
  sh: ../../scripts/bash/check-prerequisites.sh --json
  ps: ../../scripts/powershell/check-prerequisites.ps1 -Json
---

# Validate Testing (plan.md)

Ensure the implementation plan **explicitly mandates** both of the following. Add
any missing mandate to `plan.md` **in place** and report what was added.

1. Implementing features using **Domain-Driven Design (DDD)** principles,
   following a **red-green-refactor** test-driven-development workflow.
2. After each feature is implemented, using **Playwright** to verify the feature
   works correctly **end-to-end**.

## User Input

```text
$ARGUMENTS
```

`$ARGUMENTS` is an optional path override (a `plan.md` path or feature
directory). When empty, resolve the feature automatically.

## Prerequisites

1. Run `.specify/scripts/bash/check-prerequisites.sh --json` and parse
   `FEATURE_DIR`. On failure, use the `$ARGUMENTS` override.
2. Read `FEATURE_DIR/plan.md`. If it is missing, report and stop.

## Audit

Scan `plan.md` for an **explicit** statement of each mandate above. A vague
mention of "tests" does not satisfy mandate 1 — it must require DDD with a
red-green-refactor TDD loop. A mention of generic e2e does not satisfy mandate 2
unless it requires Playwright verification after each feature.

## Apply

- For each mandate that is **absent or only implied**, add an explicit statement
  to the most appropriate place in `plan.md` (e.g. a "Testing Strategy" /
  "Constraints" section, creating a short section if none exists).
- Use clear, imperative wording, for example:
  - "All features MUST be implemented using Domain-Driven Design (DDD) with a
    red-green-refactor TDD workflow: write a failing test, make it pass with the
    minimal change, then refactor."
  - "After each feature is implemented, it MUST be verified end-to-end with
    Playwright before the feature is considered done."
- Do not duplicate a mandate already stated. Preserve existing content. Edit
  `plan.md` **in place**.

## Report

State which mandates were already present and which you added (with the section
they were added to). If both were already explicit, say so and make no edits.
