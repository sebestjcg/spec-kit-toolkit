---
description: "Resolve unchecked checklist items from requirements docs, then the codebase, then by asking the user via AskUserQuestion in batches of 5."
scripts:
  sh: ../../scripts/bash/check-prerequisites.sh --json
  ps: ../../scripts/powershell/check-prerequisites.ps1 -Json
---

# Resolve Checklist

For each **unchecked** checklist item, resolve an answer using a strict priority
order of sources. When an item is resolved, **check it off (`- [x]`) only** — do
not write any annotation into the checklist. Edit the checklist file(s) **in
place** and print a concise summary.

## User Input

```text
$ARGUMENTS
```

`$ARGUMENTS` may contain, in any order:

- A **requirements-docs path** (a directory or file of requirements; default
  candidate: `documentation/requirements/`).
- A **codebase path** (a directory to search for the answer in source code).
- A checklist path / feature-directory override.

If a requirements-docs path or a codebase path is **not** supplied, ask the user
for it before relying on that source (see Resolution order). Do not guess paths.

## Prerequisites

1. Run `.specify/scripts/bash/check-prerequisites.sh --json` and parse
   `FEATURE_DIR`. On failure, fall back to the override path in `$ARGUMENTS`.
2. Locate checklist(s) under `FEATURE_DIR/checklists/*.md`, or an inline
   review/acceptance section in `FEATURE_DIR/spec.md`, or the explicit path from
   `$ARGUMENTS`. If none found, report and stop.

## Resolution order (per unchecked item)

For every item still marked `- [ ]`, attempt resolution in this order and stop at
the first source that conclusively answers it:

1. **Requirements docs.** Search the requirements-docs path. If that path was not
   provided in `$ARGUMENTS`, ask the user for it once before this step.
2. **Codebase.** Search the codebase path for evidence the criterion is met. If
   that path was not provided, ask the user for it once before this step.
3. **Ask the user.** Anything still unresolved after steps 1–2 is collected and
   asked back to the user with the **`AskUserQuestion`** tool, **in batches of 5
   questions** (call the tool repeatedly, at most 5 questions per call, until all
   open items are answered or the user declines).

An item counts as resolved only when a source affirmatively confirms it (docs,
code, or a user answer). If the user indicates it is not satisfied, leave it
unchecked.

## Apply

- For each resolved item, rewrite its `- [ ]` to `- [x]`, preserving the item
  text exactly. Add **no** other text to the checklist.
- Leave unresolved / negatively-answered items as `- [ ]`.
- Write each modified checklist back **in place**.

## Report

Print a concise per-file summary: how many items were resolved, and from which
source tier (docs / code / asked). List any items the user left unresolved.
