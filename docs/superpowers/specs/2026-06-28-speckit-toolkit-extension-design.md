# Design: `speckit.toolkit` extension

**Date:** 2026-06-28
**Status:** Approved (design phase)
**Source requirements:** `documentation/requirements/new_commands.md`

## 1. Overview & approach

A single Spec Kit **extension** (id `toolkit`) that ships six net-new, namespaced
commands supporting the author's spec-driven workflow.

Because these commands do not exist in spec-kit core, they need **none** of the
semantic-delta / regenerate-via-`claude -p` machinery used by this repo's
`claude-ask-questions` **preset**. That machinery exists only to track upstream
changes to core commands that the preset *overrides*. These six are brand-new
commands with no upstream counterpart, so they are plain, **static command
markdown files** — simpler to build, ship, and maintain.

Extensions *add* new namespaced commands; presets *override* existing core
commands. Adding new commands ⇒ extension is the correct vehicle.

## 2. Repository layout

```
extensions/toolkit/
  extension.yml          # manifest (id: toolkit, version stamped by package.sh)
  README.md              # what/why/install, mirrors the preset README style
  LICENSE                # MIT
  commands/
    speckit.toolkit.tick-checklist.md
    speckit.toolkit.resolve-checklist.md
    speckit.toolkit.validate-plan.md
    speckit.toolkit.validate-testing.md
    speckit.toolkit.validate-tasks.md
    speckit.toolkit.research.md
```

The extension ships **no `scripts/`, no config file, no MCP tools, no hooks, no
PowerShell**. `scripts/package.sh` already globs `extensions/*/extension.yml`,
so it builds `toolkit-<version>.zip` with zero changes to the packaging script.
The root `README.md` gains an "Extensions" section/table alongside the existing
"Presets" table.

## 3. Naming constraint (load-bearing)

The spec-kit extension manifest validator enforces a strict regex on command
names:

```
provides.commands[].name   pattern: ^speckit\.[a-z0-9-]+\.[a-z0-9-]+$
                           format:  speckit.{extension-id}.{command-name}
```

Flat / hyphenated forms (e.g. `speckit-toolkit-tick-checklist`) are explicitly
**invalid** and will fail `specify extension add`. All command names therefore
use the dotted form with extension id `toolkit`. Extension id matches
`^[a-z0-9-]+$`; aliases (none used here) would have to share the `toolkit`
namespace.

## 4. Artifact discovery (shared by all commands)

Commands are agent-driven markdown. To locate the active feature's files
(`spec.md`, `plan.md`, `tasks.md`, `checklists/`, `research.md`,
`data-model.md`, `quickstart.md`), each command instructs the agent to run
spec-kit's existing `.specify/scripts/bash/check-prerequisites.sh --json`
(present in every spec-kit project) to resolve `FEATURE_DIR`, and accepts an
optional path override in `$ARGUMENTS`. The extension ships **no scripts of its
own** — it reuses core's prerequisite script.

## 5. The six commands

### 5.1 `speckit.toolkit.tick-checklist`
Locates the feature's review / acceptance checklist(s), reads each `- [ ]` item,
evaluates it against `spec.md`, and **checks off (`- [x]`) only the items the
spec demonstrably satisfies**, leaving unmet items unchecked. Edits the
checklist file(s) **in place**. Reports a concise summary (e.g. "checked 7/12;
unmet: …").

### 5.2 `speckit.toolkit.resolve-checklist`
For each unchecked checklist item, resolves an answer in priority order:
1. The **requirements-docs path** (supplied as a command argument; the command
   asks the user if it is absent).
2. The **codebase path** (supplied as a command argument; asks if absent).
3. Anything still unresolved is collected and asked back to the user via the
   `AskUserQuestion` tool **in batches of 5 questions**.

When an item is resolved, the command **checks it off (`- [x]`) only** — no
verbose annotation is written into the checklist. Edits **in place**.

### 5.3 `speckit.toolkit.validate-plan`
Audits `plan.md` plus its implementation-detail files. Determines whether the
intended task sequence is derivable from what is written, and for each
core-implementation / refinement step **inserts cross-references to the relevant
section(s) of the implementation-detail files** where they are missing. **Edits
`plan.md` in place**; reports what was added.

### 5.4 `speckit.toolkit.validate-testing`
Ensures `plan.md` **explicitly mandates**:
1. Implementing features using Domain-Driven Design (DDD) with a
   red-green-refactor test-driven-development workflow.
2. Playwright end-to-end verification after each feature is implemented.

Missing mandates are **added to `plan.md` in place**; reports what was added.

### 5.5 `speckit.toolkit.validate-tasks`
Same two mandates as 5.4, enforced against `tasks.md`. **Edits `tasks.md` in
place** to add explicit red-green-refactor task steps and Playwright
end-to-end-verification task entries wherever they are absent; reports changes.

### 5.6 `speckit.toolkit.research`
Embeds the author's Path A / Path B decision-gate research prompt
(`documentation/requirements/new_commands.md`, `/speckit-research` row)
near-verbatim, wired to spec-kit artifacts:
- Reads the implementation plan, `plan.md`, `research.md`, `data-model.md`,
  `quickstart.md`, and any referenced specs **before** deciding.
- States the routing decision (Path A narrow vs. Path B broad) in writing, with
  one sentence of justification, applying the load-bearing test to every
  candidate research item.
- Pins exact library version(s) into `research.md` before researching.
- Spawns **parallel research subagents** (the Agent tool with WebSearch /
  WebFetch), each scoped to one concrete, version-pinned question — never
  "study library X".
- Reconciles findings back into `research.md`, preserving recorded versions and
  the resolved decision/rationale per area, and flagging anything unresolved or
  contradictory.

## 6. Behavior conventions

- All file-mutating commands (`tick-checklist`, `resolve-checklist`,
  `validate-plan`, `validate-testing`, `validate-tasks`) **edit in place** and
  print a concise report of what changed.
- Each command file carries front matter with a `description:` field.
- The manifest's `provides.commands[]` maps each dotted `name` to its `file`.

## 7. Distribution

- Install: `specify extension add --from <release-zip-url>` or, from a local
  clone, `specify extension add --dev ./extensions/toolkit`.
- Release flow mirrors the preset: `scripts/package.sh` stamps the version,
  builds `toolkit-<version>.zip` (config file at the zip root), and cuts the
  GitHub Release.

## 8. Out of scope (YAGNI)

- Regenerate / semantic-delta machinery (only needed for overriding core).
- Config files / per-project path configuration (paths come via `$ARGUMENTS`).
- Hooks, MCP tool dependencies, PowerShell script variants.
- Splitting into multiple themed extensions (one extension was chosen).

## 9. Risks & open questions

- **Validator strictness beyond names:** the manifest validator may enforce
  additional fields; mitigated by following the documented `extension.yml`
  schema (`schema_version`, `extension.{id,name,version,description,author,
  repository,license}`, `requires.speckit_version`, `provides.commands[]`).
- **`check-prerequisites.sh` availability/flags:** the commands assume the
  standard bash script path and `--json` output. If a target project uses the
  PowerShell variant or a different layout, the commands fall back to the
  `$ARGUMENTS` path override.
- **Checklist location variance:** review/acceptance checklists may live under
  `checklists/` or inline in `spec.md` depending on spec-kit version; the
  tick/resolve commands locate them relative to `FEATURE_DIR` and degrade
  gracefully if none are found.
