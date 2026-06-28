---
description: "Audit plan.md and its implementation-detail files and insert missing cross-references from implementation steps to the relevant detail sections."
scripts:
  sh: ../../scripts/bash/check-prerequisites.sh --json
  ps: ../../scripts/powershell/check-prerequisites.ps1 -Json
---

# Validate Plan

Audit the implementation plan and its implementation-detail files. Determine
whether a reader could derive the intended **sequence of tasks** from what is
written, and where a core-implementation or refinement step relies on a detail
file, **insert a cross-reference** to the relevant section(s) of that detail
file. Edit `plan.md` **in place** and report what was added.

## User Input

```text
$ARGUMENTS
```

`$ARGUMENTS` is an optional path override (a `plan.md` path or feature
directory). When empty, resolve the feature automatically.

## Prerequisites

1. Run `.specify/scripts/bash/check-prerequisites.sh --json` and parse
   `FEATURE_DIR` and `AVAILABLE_DOCS`. On failure, use the `$ARGUMENTS` override.
2. Read `FEATURE_DIR/plan.md`. If it is missing, report and stop.

## Gather implementation-detail files

From `AVAILABLE_DOCS` and `FEATURE_DIR`, read every implementation-detail file
that exists, e.g. `research.md`, `data-model.md`, `quickstart.md`, `contracts/`,
and anything `plan.md` itself references. These are the cross-reference targets.

## Audit

1. Walk `plan.md` in order, focusing on the **core implementation** and
   **refinement** steps.
2. Ask, for each step: could an implementer derive the concrete next action from
   what is written, or do they need to know which detail file/section holds the
   information? Identify steps whose detail lives in a separate file but which do
   **not** point to it.
3. For each such step, determine the precise detail file and section that backs
   it (e.g. a specific heading in `data-model.md` or `research.md`).

## Apply cross-references

- For each gap, insert a concise **cross-reference** inline at the step, naming
  the target file and section, e.g.
  `(see data-model.md → "Booking aggregate")`.
- Only add references where they are missing; do not duplicate ones already
  present, and do not rewrite the surrounding prose.
- Preserve all existing content and ordering. Edit `plan.md` **in place**.

## Report

List each cross-reference added, as `plan.md step → target file/section`. If the
task sequence is already fully derivable and no references were missing, say so
explicitly and make no edits.
