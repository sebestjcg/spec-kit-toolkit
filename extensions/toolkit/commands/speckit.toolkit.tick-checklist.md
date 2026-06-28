---
description: "Check off review/acceptance checklist items that the feature spec demonstrably satisfies, leaving unmet items unchecked."
scripts:
  sh: ../../scripts/bash/check-prerequisites.sh --json
  ps: ../../scripts/powershell/check-prerequisites.ps1 -Json
---

# Tick Checklist

Read the feature's review / acceptance checklist(s), evaluate each item against
the feature specification, and **check off (`- [x]`) only the items the spec
demonstrably satisfies**. Leave every unmet or unverifiable item unchecked. Edit
the checklist file(s) **in place** and print a concise summary.

## User Input

```text
$ARGUMENTS
```

`$ARGUMENTS` is optional. Treat it as an explicit path override pointing at a
checklist file, a `checklists/` directory, or the feature directory. When it is
empty, resolve the feature automatically (see Prerequisites).

## Prerequisites

1. Run `.specify/scripts/bash/check-prerequisites.sh --json` from the repo root
   and parse the JSON for `FEATURE_DIR` (and `AVAILABLE_DOCS`).
2. If the script is unavailable (e.g. PowerShell-only project or non-standard
   layout) or fails, fall back to the path supplied in `$ARGUMENTS`. If neither
   resolves a feature directory, stop and tell the user how to point you at one.

## Locate the checklist(s)

- If `$ARGUMENTS` names a specific file or directory, use that — it takes
  precedence over auto-discovery below.
- Otherwise, look for checklist files under `FEATURE_DIR/checklists/` (any
  `*.md`).
- If none exist there, look for an inline "review" / "acceptance" checklist
  section inside `FEATURE_DIR/spec.md`.
- If no checklist is found anywhere, report that and stop — do not invent one.

## Evaluate and tick

1. Read `FEATURE_DIR/spec.md` (the source of truth for what is satisfied).
2. For each checklist, parse every `- [ ]` item.
3. For each item, decide whether `spec.md` **demonstrably** satisfies it:
   - Satisfied (the spec clearly and unambiguously meets the criterion) →
     rewrite that line's `- [ ]` to `- [x]`, preserving the item text exactly.
   - Not satisfied, or you are unsure → leave it as `- [ ]`.
4. Do **not** add annotations, comments, or sub-bullets to the checklist; the
   only change is the box state. Preserve all other content and formatting.
5. Write each modified checklist back **in place**.

## Report

Print a concise summary per checklist file, for example:

```
checklists/requirements.md — checked 7/12
  unmet: item #3 (error states), item #8 (i18n), …
```

List the unmet items briefly so the user knows what still needs work. Do not
print the full checklist back.
