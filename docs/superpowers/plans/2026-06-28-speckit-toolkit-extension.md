# `speckit.toolkit` Extension Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a single Spec Kit extension (id `toolkit`) providing six net-new, namespaced, static-markdown commands that support the author's spec-driven workflow.

**Architecture:** Plain agent-driven markdown command files plus an `extension.yml` manifest under `extensions/toolkit/`. No scripts, hooks, config, MCP tools, or PowerShell. Commands resolve the active feature via core spec-kit's `check-prerequisites.sh --json` (declared in front matter, path-rewritten by the CLI at registration) and accept a `$ARGUMENTS` path override. A repo-root Python validator (`scripts/validate_toolkit.py`, not shipped in the zip) acts as the test harness.

**Tech Stack:** Markdown command files, YAML manifest, Python 3 (stdlib + PyYAML) for the validator, existing `scripts/package.sh` for distribution.

## Global Constraints

- Extension id: `toolkit` (matches `^[a-z0-9-]+$`).
- Every command name MUST match `^speckit\.[a-z0-9-]+\.[a-z0-9-]+$` and use the exact form `speckit.toolkit.<command-name>`. Flat/hyphenated forms are invalid.
- The extension ships **no** `scripts/`, config file, MCP tools, hooks, or PowerShell. It reuses core's `check-prerequisites.sh`.
- Manifest fields required by the validator: `schema_version`; `extension.{id,name,version,description,author,repository,license}`; `requires.speckit_version`; `provides.commands[].{name,file,description}`.
- `version:` in `extension.yml` is auto-stamped by `scripts/package.sh` (it `sed`-replaces `^  version: "..."`). Seed it as `"0.0.0"`; do not hand-maintain it.
- `author: "sebestjcg"`, `repository: "https://github.com/sebestjcg/spec-kit-toolkit"`, `license: "MIT"` — matching the existing `claude-ask-questions` preset.
- Each command file is static markdown with YAML front matter containing a `description:` field. File-mutating commands edit **in place** and print a concise change report.
- Commands resolve `FEATURE_DIR` by running `.specify/scripts/bash/check-prerequisites.sh --json` (declared in front matter as `../../scripts/bash/check-prerequisites.sh --json`), and accept an optional path override from `$ARGUMENTS`.

---

## File Structure

| File | Responsibility |
| ---- | -------------- |
| `extensions/toolkit/extension.yml` | Manifest: id, metadata, `requires`, `provides.commands[]` mapping each name → file. |
| `extensions/toolkit/LICENSE` | MIT license (copy of preset LICENSE). |
| `extensions/toolkit/README.md` | What/why/install, mirroring preset README style; command table. |
| `extensions/toolkit/commands/speckit.toolkit.tick-checklist.md` | Check off checklist items the spec satisfies. |
| `extensions/toolkit/commands/speckit.toolkit.resolve-checklist.md` | Resolve unchecked items via docs → code → AskUserQuestion (batches of 5). |
| `extensions/toolkit/commands/speckit.toolkit.validate-plan.md` | Audit `plan.md`; insert cross-references to implementation-detail files. |
| `extensions/toolkit/commands/speckit.toolkit.validate-testing.md` | Ensure `plan.md` mandates DDD red-green-refactor TDD + Playwright e2e. |
| `extensions/toolkit/commands/speckit.toolkit.validate-tasks.md` | Ensure `tasks.md` contains explicit red-green-refactor + Playwright task entries. |
| `extensions/toolkit/commands/speckit.toolkit.research.md` | Path A / Path B decision-gate research wired to spec-kit artifacts. |
| `scripts/validate_toolkit.py` | Test harness: validates manifest + per-command structure/content. NOT packaged. |
| `README.md` (root) | Gains an "Extensions" section/table alongside "Presets". |

`scripts/package.sh` needs **no change** — it already globs `extensions/*/extension.yml`.

---

## Task 1: Validator harness + manifest skeleton

**Files:**
- Create: `scripts/validate_toolkit.py`
- Create: `extensions/toolkit/extension.yml`
- Create: `extensions/toolkit/LICENSE`

**Interfaces:**
- Produces: `scripts/validate_toolkit.py` with CLI:
  - `python3 scripts/validate_toolkit.py manifest` — validates `extensions/toolkit/extension.yml` only.
  - `python3 scripts/validate_toolkit.py command <name>` — validates one command file by manifest name.
  - `python3 scripts/validate_toolkit.py all` — manifest + every command listed in the manifest.
  - Exit 0 on success, 1 on any failure; prints `OK: …` / `FAIL: …` lines.
- Produces: `extensions/toolkit/extension.yml` declaring exactly six `provides.commands[]` entries with names `speckit.toolkit.{tick-checklist,resolve-checklist,validate-plan,validate-testing,validate-tasks,research}` and files `commands/<name>.md`.

- [ ] **Step 1: Write the failing test (the validator itself)**

Create `scripts/validate_toolkit.py`:

```python
#!/usr/bin/env python3
"""Structural validator / test harness for the `toolkit` extension.

Usage:
  validate_toolkit.py manifest          # validate extension.yml only
  validate_toolkit.py command <name>    # validate one command file
  validate_toolkit.py all               # manifest + all command files
"""
import re
import sys
from pathlib import Path

import yaml

REPO = Path(__file__).resolve().parents[1]
EXT = REPO / "extensions" / "toolkit"
MANIFEST = EXT / "extension.yml"

NAME_RE = re.compile(r"^speckit\.[a-z0-9-]+\.[a-z0-9-]+$")

EXPECTED_NAMES = [
    "speckit.toolkit.tick-checklist",
    "speckit.toolkit.resolve-checklist",
    "speckit.toolkit.validate-plan",
    "speckit.toolkit.validate-testing",
    "speckit.toolkit.validate-tasks",
    "speckit.toolkit.research",
]

# Per-command required substrings (case-insensitive). Each command task turns
# its row green by including these markers in the command body.
CONTENT_MARKERS = {
    "speckit.toolkit.tick-checklist": ["$ARGUMENTS", "check-prerequisites", "- [x]", "spec.md"],
    "speckit.toolkit.resolve-checklist": ["$ARGUMENTS", "AskUserQuestion", "batches of 5", "- [x]"],
    "speckit.toolkit.validate-plan": ["$ARGUMENTS", "check-prerequisites", "plan.md", "cross-reference"],
    "speckit.toolkit.validate-testing": ["$ARGUMENTS", "plan.md", "Domain-Driven Design", "red-green-refactor", "Playwright"],
    "speckit.toolkit.validate-tasks": ["$ARGUMENTS", "tasks.md", "Domain-Driven Design", "red-green-refactor", "Playwright"],
    "speckit.toolkit.research": ["$ARGUMENTS", "Path A", "Path B", "load-bearing", "version", "parallel"],
}

errors = []


def fail(msg):
    errors.append(msg)


def load_manifest():
    if not MANIFEST.exists():
        fail(f"manifest missing: {MANIFEST}")
        return None
    data = yaml.safe_load(MANIFEST.read_text(encoding="utf-8"))
    return data


def validate_manifest():
    data = load_manifest()
    if data is None:
        return
    if data.get("schema_version") != "1.0":
        fail('schema_version must be "1.0"')
    ext = data.get("extension", {})
    for field in ("id", "name", "version", "description", "author", "repository", "license"):
        if not ext.get(field):
            fail(f"extension.{field} missing")
    if ext.get("id") != "toolkit":
        fail('extension.id must be "toolkit"')
    if not data.get("requires", {}).get("speckit_version"):
        fail("requires.speckit_version missing")
    cmds = data.get("provides", {}).get("commands", [])
    names = [c.get("name") for c in cmds]
    if names != EXPECTED_NAMES:
        fail(f"provides.commands names mismatch.\n  expected: {EXPECTED_NAMES}\n  got:      {names}")
    for c in cmds:
        name, file = c.get("name"), c.get("file")
        if not NAME_RE.match(name or ""):
            fail(f"name fails regex: {name!r}")
        if not c.get("description"):
            fail(f"description missing for {name}")
        if file != f"commands/{name}.md":
            fail(f"file path for {name} should be 'commands/{name}.md', got {file!r}")
    if not errors:
        print(f"OK: manifest ({len(cmds)} commands)")


def validate_command(name):
    if name not in CONTENT_MARKERS:
        fail(f"unknown command: {name}")
        return
    path = EXT / "commands" / f"{name}.md"
    if not path.exists():
        fail(f"command file missing: {path}")
        return
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        fail(f"{name}: missing YAML front matter")
    fm_end = text.find("---", 3)
    front = text[3:fm_end] if fm_end != -1 else ""
    if "description:" not in front:
        fail(f"{name}: front matter missing description")
    low = text.lower()
    for marker in CONTENT_MARKERS[name]:
        if marker.lower() not in low:
            fail(f"{name}: missing required content marker {marker!r}")
    if not [e for e in errors if name in e]:
        print(f"OK: command {name}")


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(2)
    mode = sys.argv[1]
    if mode == "manifest":
        validate_manifest()
    elif mode == "command":
        validate_command(sys.argv[2])
    elif mode == "all":
        validate_manifest()
        for n in EXPECTED_NAMES:
            validate_command(n)
    else:
        print(f"unknown mode: {mode}")
        sys.exit(2)
    if errors:
        for e in errors:
            print(f"FAIL: {e}")
        sys.exit(1)
    sys.exit(0)


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Run the manifest test to verify it fails**

Run: `python3 scripts/validate_toolkit.py manifest`
Expected: FAIL — prints `FAIL: manifest missing: …/extensions/toolkit/extension.yml`, exit 1.

- [ ] **Step 3: Create the manifest**

Create `extensions/toolkit/extension.yml`:

```yaml
schema_version: "1.0"

extension:
  id: toolkit
  name: "Spec Kit Toolkit"
  version: "0.0.0"
  description: "Six workflow commands that tick/resolve review checklists, audit plans and tasks for cross-references and DDD red-green-refactor + Playwright mandates, and run a Path A/Path B decision-gate research pass against spec-kit artifacts."
  author: "sebestjcg"
  repository: "https://github.com/sebestjcg/spec-kit-toolkit"
  license: "MIT"
  category: "docs"
  effect: "read-write"

requires:
  speckit_version: ">=0.6.0"

provides:
  commands:
    - name: speckit.toolkit.tick-checklist
      file: commands/speckit.toolkit.tick-checklist.md
      description: "Check off review/acceptance checklist items that the feature spec demonstrably satisfies, leaving unmet items unchecked."
    - name: speckit.toolkit.resolve-checklist
      file: commands/speckit.toolkit.resolve-checklist.md
      description: "Resolve unchecked checklist items from requirements docs, then the codebase, then by asking the user via AskUserQuestion in batches of 5."
    - name: speckit.toolkit.validate-plan
      file: commands/speckit.toolkit.validate-plan.md
      description: "Audit plan.md and its implementation-detail files and insert missing cross-references from implementation steps to the relevant detail sections."
    - name: speckit.toolkit.validate-testing
      file: commands/speckit.toolkit.validate-testing.md
      description: "Ensure plan.md explicitly mandates DDD red-green-refactor TDD and post-feature Playwright end-to-end verification."
    - name: speckit.toolkit.validate-tasks
      file: commands/speckit.toolkit.validate-tasks.md
      description: "Ensure tasks.md contains explicit red-green-refactor task steps and Playwright end-to-end verification entries for each feature."
    - name: speckit.toolkit.research
      file: commands/speckit.toolkit.research.md
      description: "Run a Path A/Path B decision-gate research pass: pin versions into research.md and fan out parallel, version-pinned research subagents."

tags:
  - "checklist"
  - "plan"
  - "tasks"
  - "research"
  - "tdd"
  - "playwright"
```

- [ ] **Step 4: Create the LICENSE**

Run: `git show HEAD:presets/claude-ask-questions/LICENSE > extensions/toolkit/LICENSE`
Expected: creates `extensions/toolkit/LICENSE` identical to the preset's MIT license.

- [ ] **Step 5: Run the manifest test to verify it passes**

Run: `python3 scripts/validate_toolkit.py manifest`
Expected: PASS — prints `OK: manifest (6 commands)`, exit 0.

- [ ] **Step 6: Commit**

```bash
git add scripts/validate_toolkit.py extensions/toolkit/extension.yml extensions/toolkit/LICENSE
git commit -m "feat(toolkit): add extension manifest, license, and validator harness"
```

---

## Task 2: `speckit.toolkit.tick-checklist` command

**Files:**
- Create: `extensions/toolkit/commands/speckit.toolkit.tick-checklist.md`

**Interfaces:**
- Consumes: validator from Task 1 (`python3 scripts/validate_toolkit.py command speckit.toolkit.tick-checklist`). Required content markers: `$ARGUMENTS`, `check-prerequisites`, `- [x]`, `spec.md`.

- [ ] **Step 1: Run the test to verify it fails**

Run: `python3 scripts/validate_toolkit.py command speckit.toolkit.tick-checklist`
Expected: FAIL — `FAIL: …: command file missing`, exit 1.

- [ ] **Step 2: Write the command file**

Create `extensions/toolkit/commands/speckit.toolkit.tick-checklist.md`:

````markdown
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

- Look for checklist files under `FEATURE_DIR/checklists/` (any `*.md`).
- If none exist there, look for an inline "review" / "acceptance" checklist
  section inside `FEATURE_DIR/spec.md`.
- If `$ARGUMENTS` named a specific file or directory, use that instead.
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
````

- [ ] **Step 3: Run the test to verify it passes**

Run: `python3 scripts/validate_toolkit.py command speckit.toolkit.tick-checklist`
Expected: PASS — `OK: command speckit.toolkit.tick-checklist`, exit 0.

- [ ] **Step 4: Commit**

```bash
git add extensions/toolkit/commands/speckit.toolkit.tick-checklist.md
git commit -m "feat(toolkit): add tick-checklist command"
```

---

## Task 3: `speckit.toolkit.resolve-checklist` command

**Files:**
- Create: `extensions/toolkit/commands/speckit.toolkit.resolve-checklist.md`

**Interfaces:**
- Consumes: validator (`command speckit.toolkit.resolve-checklist`). Required markers: `$ARGUMENTS`, `AskUserQuestion`, `batches of 5`, `- [x]`.

- [ ] **Step 1: Run the test to verify it fails**

Run: `python3 scripts/validate_toolkit.py command speckit.toolkit.resolve-checklist`
Expected: FAIL — command file missing, exit 1.

- [ ] **Step 2: Write the command file**

Create `extensions/toolkit/commands/speckit.toolkit.resolve-checklist.md`:

````markdown
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
````

- [ ] **Step 3: Run the test to verify it passes**

Run: `python3 scripts/validate_toolkit.py command speckit.toolkit.resolve-checklist`
Expected: PASS — `OK: command speckit.toolkit.resolve-checklist`, exit 0.

- [ ] **Step 4: Commit**

```bash
git add extensions/toolkit/commands/speckit.toolkit.resolve-checklist.md
git commit -m "feat(toolkit): add resolve-checklist command"
```

---

## Task 4: `speckit.toolkit.validate-plan` command

**Files:**
- Create: `extensions/toolkit/commands/speckit.toolkit.validate-plan.md`

**Interfaces:**
- Consumes: validator (`command speckit.toolkit.validate-plan`). Required markers: `$ARGUMENTS`, `check-prerequisites`, `plan.md`, `cross-reference`.

- [ ] **Step 1: Run the test to verify it fails**

Run: `python3 scripts/validate_toolkit.py command speckit.toolkit.validate-plan`
Expected: FAIL — command file missing, exit 1.

- [ ] **Step 2: Write the command file**

Create `extensions/toolkit/commands/speckit.toolkit.validate-plan.md`:

````markdown
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
````

- [ ] **Step 3: Run the test to verify it passes**

Run: `python3 scripts/validate_toolkit.py command speckit.toolkit.validate-plan`
Expected: PASS — `OK: command speckit.toolkit.validate-plan`, exit 0.

- [ ] **Step 4: Commit**

```bash
git add extensions/toolkit/commands/speckit.toolkit.validate-plan.md
git commit -m "feat(toolkit): add validate-plan command"
```

---

## Task 5: `speckit.toolkit.validate-testing` command

**Files:**
- Create: `extensions/toolkit/commands/speckit.toolkit.validate-testing.md`

**Interfaces:**
- Consumes: validator (`command speckit.toolkit.validate-testing`). Required markers: `$ARGUMENTS`, `plan.md`, `Domain-Driven Design`, `red-green-refactor`, `Playwright`.

- [ ] **Step 1: Run the test to verify it fails**

Run: `python3 scripts/validate_toolkit.py command speckit.toolkit.validate-testing`
Expected: FAIL — command file missing, exit 1.

- [ ] **Step 2: Write the command file**

Create `extensions/toolkit/commands/speckit.toolkit.validate-testing.md`:

````markdown
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
````

- [ ] **Step 3: Run the test to verify it passes**

Run: `python3 scripts/validate_toolkit.py command speckit.toolkit.validate-testing`
Expected: PASS — `OK: command speckit.toolkit.validate-testing`, exit 0.

- [ ] **Step 4: Commit**

```bash
git add extensions/toolkit/commands/speckit.toolkit.validate-testing.md
git commit -m "feat(toolkit): add validate-testing command"
```

---

## Task 6: `speckit.toolkit.validate-tasks` command

**Files:**
- Create: `extensions/toolkit/commands/speckit.toolkit.validate-tasks.md`

**Interfaces:**
- Consumes: validator (`command speckit.toolkit.validate-tasks`). Required markers: `$ARGUMENTS`, `tasks.md`, `Domain-Driven Design`, `red-green-refactor`, `Playwright`.

- [ ] **Step 1: Run the test to verify it fails**

Run: `python3 scripts/validate_toolkit.py command speckit.toolkit.validate-tasks`
Expected: FAIL — command file missing, exit 1.

- [ ] **Step 2: Write the command file**

Create `extensions/toolkit/commands/speckit.toolkit.validate-tasks.md`:

````markdown
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
  position, matching the existing task numbering / checkbox style in `tasks.md`,
  for example:
  - `- [ ] Write a failing test for <behavior> (red) before implementing.`
  - `- [ ] Implement the minimal code to make the test pass (green).`
  - `- [ ] Refactor with tests green; keep the domain model clean (refactor).`
  - `- [ ] Verify <feature> end-to-end with Playwright.`
- Do not duplicate steps that already exist. Preserve existing tasks, numbering,
  and formatting. Edit `tasks.md` **in place**.

## Report

List the task entries added, grouped by the feature they were added to. If every
feature already had both, say so and make no edits.
````

- [ ] **Step 3: Run the test to verify it passes**

Run: `python3 scripts/validate_toolkit.py command speckit.toolkit.validate-tasks`
Expected: PASS — `OK: command speckit.toolkit.validate-tasks`, exit 0.

- [ ] **Step 4: Commit**

```bash
git add extensions/toolkit/commands/speckit.toolkit.validate-tasks.md
git commit -m "feat(toolkit): add validate-tasks command"
```

---

## Task 7: `speckit.toolkit.research` command

**Files:**
- Create: `extensions/toolkit/commands/speckit.toolkit.research.md`

**Interfaces:**
- Consumes: validator (`command speckit.toolkit.research`). Required markers: `$ARGUMENTS`, `Path A`, `Path B`, `load-bearing`, `version`, `parallel`.

- [ ] **Step 1: Run the test to verify it fails**

Run: `python3 scripts/validate_toolkit.py command speckit.toolkit.research`
Expected: FAIL — command file missing, exit 1.

- [ ] **Step 2: Write the command file**

Create `extensions/toolkit/commands/speckit.toolkit.research.md`:

````markdown
---
description: "Run a Path A/Path B decision-gate research pass: pin versions into research.md and fan out parallel, version-pinned research subagents."
scripts:
  sh: ../../scripts/bash/check-prerequisites.sh --json
  ps: ../../scripts/powershell/check-prerequisites.ps1 -Json
---

# Research (decision-gate)

Run a targeted research pass for the active feature and reconcile findings into
`research.md`. The failure mode you are explicitly avoiding is untargeted,
general-purpose library scanning ("tell me about library X") that returns broad
summaries instead of answers that unblock a specific implementation step.

## User Input

```text
$ARGUMENTS
```

`$ARGUMENTS` is optional: a feature-directory override and/or a free-text focus
("research the map legend feature"). When empty, resolve the feature
automatically and research the unknowns surfaced by the plan.

## Prerequisites

1. Run `.specify/scripts/bash/check-prerequisites.sh --json` and parse
   `FEATURE_DIR` and `AVAILABLE_DOCS`. On failure, use the `$ARGUMENTS` override.
2. **Read the inputs before deciding**: the implementation plan, `plan.md`,
   `research.md`, `data-model.md`, `quickstart.md`, and any referenced specs that
   exist under `FEATURE_DIR`.

## Decision gate (do this first, in writing)

1. Apply the **load-bearing test** to every candidate research item: "Does
   answering this resolve a specific implementation decision I am currently
   unsure about?" If you cannot phrase it as one targeted question with a
   verifiable answer, it is too broad — it belongs in Path B enumeration.
2. State your routing decision explicitly — **"Path A"** or **"Path B"** — with
   one sentence of justification grounded in what you read.

**Calibration**

- NARROW → **Path A**: one library/API surface with bounded, version-specific
  unknowns you can already name (e.g. "Confirm the invocation signature and
  breaking changes for d3-scale v4 sequential color scales").
- BROAD or AMBIGUOUS → **Path B**: a whole subsystem, multiple interacting
  libraries, or a vague directive where naive fan-out would just scan each
  library in general.
- Tie-breaker: if it reduces to one library and you can name the concrete
  unknowns, go A. Otherwise go B. When genuinely on the fence, prefer B.

**Edge cases — handle explicitly, don't default**

- **Mixed scope**: split it — spawn Path A tasks for the targeted parts, run
  Path B enumeration on the broad remainder. Say you are doing this.
- **Scope grows mid-decision**: downgrade the affected portion to Path B rather
  than forcing premature tasks.
- **No genuine research needed**: if nothing meets the load-bearing test, do not
  spawn tasks. Say so and stop.
- **Too many questions**: prioritize by implementation risk/impact, research the
  top questions in parallel, and list the deferred ones explicitly.

## Path A — Well-scoped: research directly in parallel

1. Go through the plan and implementation details for areas that would benefit
   from research, prioritizing libraries/APIs that are rapidly changing or
   version-sensitive.
2. For each, **pin the exact version(s)** this app will use and record them in
   `research.md` (add/update the relevant section) **before** researching.
3. Spawn **one parallel research subagent per area** (the Agent tool with
   WebSearch / WebFetch), each scoped to a single concrete question that names
   the library, the pinned version, and the precise unknown. Never spawn a task
   whose mandate is "study library X."

## Path B — Broad/ambiguous: enumerate first, then fan out

Do NOT spawn anything yet. The trap is one task per library, each researching
that library in general.

1. Break the work down: write an explicit list of the concrete implementation
   tasks you are unsure of. Convert each into a single targeted question tied to
   a real implementation step and to a named library + pinned version, phrased so
   a correct answer directly unblocks something you will write. Reject any "learn
   about library X" entry — rewrite it as the specific thing you need to do.
2. Record the targeted **version(s)** for each question in `research.md`.
3. Only then spawn the subagents — exactly one per enumerated question — to run
   in **parallel**.

## Requirements for every research task (both paths)

- One specific, answerable, **version-pinned** question tied to a real
  implementation decision, with the library and version named in the task.
- Web research, official sources preferred — docs, changelogs, release notes for
  the pinned version.
- Each task returns: the direct answer; the source(s)/links; any version-specific
  caveats or breaking changes relative to our pinned version; and a minimal
  code/config snippet when the answer is load-bearing.

## Reconcile

After results return, reconcile findings into `research.md`, keeping the recorded
versions and the resolved decision/rationale per area. Flag anything still
unresolved, any contradiction between sources, and any new, more specific
follow-up question — don't paper over them. Edit `research.md` **in place** and
report the routing decision taken and the areas researched.
````

- [ ] **Step 3: Run the test to verify it passes**

Run: `python3 scripts/validate_toolkit.py command speckit.toolkit.research`
Expected: PASS — `OK: command speckit.toolkit.research`, exit 0.

- [ ] **Step 4: Commit**

```bash
git add extensions/toolkit/commands/speckit.toolkit.research.md
git commit -m "feat(toolkit): add research command"
```

---

## Task 8: Extension README + root README "Extensions" section + full verification

**Files:**
- Create: `extensions/toolkit/README.md`
- Modify: `README.md` (root) — add an "Extensions" section/table.

**Interfaces:**
- Consumes: the complete extension from Tasks 1–7 (`python3 scripts/validate_toolkit.py all` must pass), and `scripts/package.sh` (must build `toolkit-<version>.zip`).

- [ ] **Step 1: Run the full validator to confirm the whole extension is green**

Run: `python3 scripts/validate_toolkit.py all`
Expected: PASS — `OK: manifest (6 commands)` followed by `OK: command …` for all six, exit 0.

- [ ] **Step 2: Write the extension README**

Create `extensions/toolkit/README.md`:

```markdown
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
```

- [ ] **Step 3: Add the "Extensions" section to the root README**

In `README.md`, after the existing Presets table block and before the
"### Design principle" subsection, insert:

```markdown
## Extensions

| Extension | What it does |
| --------- | ------------ |
| [`toolkit`](./extensions/toolkit) | Six namespaced workflow commands: tick/resolve review checklists, audit plans and tasks for cross-references and DDD red-green-refactor + Playwright mandates, and run a Path A/Path B decision-gate research pass. |

```

Use the Edit tool to insert this block. Anchor the insertion on the existing
line `### Design principle: presets that survive core updates` so the new
section lands immediately above it.

- [ ] **Step 4: Build the distributable zip to confirm packaging works**

Run: `scripts/package.sh --no-release --only toolkit --out dist`
Expected: prints `packaging toolkit v… → dist/toolkit-….zip` and exits 0; the
zip contains `extension.yml`, `LICENSE`, `README.md`, and the six command files,
and **excludes** `scripts/validate_toolkit.py` (which lives at repo root, not in
`extensions/toolkit/`).

> Note: `package.sh` stamps `version:` from the locally installed `specify` CLI.
> If `specify` is not on PATH it prints a warning and leaves `version: "0.0.0"`
> unchanged — the zip still builds. That is acceptable for this verification step.

- [ ] **Step 5: Inspect the zip contents**

Run: `python3 -c "import zipfile,glob; z=zipfile.ZipFile(sorted(glob.glob('dist/toolkit-*.zip'))[-1]); print('\n'.join(sorted(z.namelist())))"`
Expected: lists exactly `LICENSE`, `README.md`, `extension.yml`, and
`commands/speckit.toolkit.*.md` (six files); no `scripts/` entries.

- [ ] **Step 6: Clean the build artifact**

Run: `rm -rf dist`
Expected: removes the throwaway `dist/` directory (it is a build output, not
committed).

- [ ] **Step 7: Commit**

```bash
git add extensions/toolkit/README.md README.md
git commit -m "docs(toolkit): add extension README and root Extensions section"
```

---

## Self-Review

**1. Spec coverage** (design doc §1–§8):

- §2 repository layout (`extension.yml`, `README.md`, `LICENSE`, `commands/` ×6, no `scripts/`) → Tasks 1, 2–7, 8. ✓
- §3 naming constraint (dotted form, regex) → enforced by the validator's `NAME_RE` + `EXPECTED_NAMES` (Task 1). ✓
- §4 artifact discovery via `check-prerequisites.sh --json` + `$ARGUMENTS` override → every command's Prerequisites section. ✓
- §5.1 tick-checklist → Task 2. §5.2 resolve-checklist (docs→code→AskUserQuestion batches of 5, check-off only) → Task 3. §5.3 validate-plan (cross-references) → Task 4. §5.4 validate-testing (plan.md, DDD r-g-r + Playwright) → Task 5. §5.5 validate-tasks (tasks.md, explicit steps) → Task 6. §5.6 research (Path A/B, version-pin, parallel subagents, reconcile) → Task 7. ✓
- §6 behavior conventions (edit in place + report; `description:` front matter; manifest maps name→file) → all command tasks + manifest. ✓
- §7 distribution (`package.sh` builds zip, `--dev` / `--from` install documented) → Task 8 + extension README. ✓
- §8 out of scope (no delta machinery, config, hooks, MCP, PowerShell variants, multi-extension split) → respected; nothing in the plan adds them. ✓

**2. Placeholder scan:** No "TBD"/"add appropriate X"/"similar to Task N" — every command file is written out in full, every command shown with expected output. ✓

**3. Type/name consistency:** The six command names are identical across the manifest (`extension.yml`), the validator's `EXPECTED_NAMES` and `CONTENT_MARKERS`, the file paths (`commands/<name>.md`), and the per-task validator invocations. The validator's required content markers for each command are all present verbatim in the corresponding command body (e.g. `Domain-Driven Design`, `red-green-refactor`, `Playwright`, `Path A`/`Path B`, `load-bearing`, `AskUserQuestion`, `batches of 5`, `- [x]`, `cross-reference`). ✓
```

