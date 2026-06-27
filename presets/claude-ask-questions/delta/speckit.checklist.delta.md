# Delta: speckit.checklist → AskUserQuestion rendering

This is a **semantic patch**, not a line patch. It describes the *only* change
this preset makes to the core `speckit.checklist` command. The generator
(`scripts/generate.sh`) hands the current core command plus this file to
`claude -p` and asks it to apply exactly this transform and nothing else.

## Global rules

- Change **only** the block described here. Every other character of the core
  command — front matter, scripts, headings, ordering, whitespace, the
  "Unit Tests for English" framing, the category structure, the item-writing
  rules, the pre/post-execution hook sections — MUST be preserved byte-for-byte.
- **Front matter is off-limits.** The YAML block between the opening and closing
  `---` lines must be copied exactly: preserve all field names, values, quotes,
  and indentation. Do not add, remove, or rename any fields (including
  `argument-hint`, `source`, `compatibility`, `metadata`, etc.). Do not change
  quoted values to unquoted or vice versa.
- **Do not add headings.** Do not insert any `#` heading lines that are not
  already present in the core command (e.g. do not add `# Speckit Checklist Skill`).
- Match the target block by its **meaning / anchor wording**, not by line
  number.
- If the target block is **not present** in the current core (upstream already
  changed it), skip the transform and leave the surrounding text untouched.
- Output the complete merged command file and nothing else (no commentary, no
  code fences).

## Transform 1 — "Question formatting rules" block

**Locate** the "Question formatting rules:" list inside the "Clarify intent
(dynamic)" step. In core it reads roughly:

```
   Question formatting rules:
   - If presenting options, generate a compact table with columns: Option | Candidate | Why It Matters
   - Limit to A–E options maximum; omit table if a free-form answer is clearer
   - Never ask the user to restate what they already said
   - Avoid speculative categories (no hallucination). If uncertain, ask explicitly: "Confirm whether X belongs in scope."
```

**Replace** that list with:

```
   Question formatting rules:
   - If presenting options, use the `AskUserQuestion` tool to present a native structured picker:
     - `question`: the checklist question text.
     - `options[]`: an array of `{label, description}` objects. For each candidate option build `{label: "<Candidate value>", description: "<Why It Matters value>"}`.
     - Append a final option `{label: "Custom", description: "Provide my own short answer (≤5 words)"}` to preserve the free-form escape hatch.
     - `multiSelect`: `false`.
   - If the user selects the "Custom" option, ask a follow-up free-text question.
   - Limit to 5 candidate options maximum (not counting the Custom escape hatch); omit the picker if a free-form answer is clearer (call `AskUserQuestion` with only `question` and a single `Custom` option).
   - Never ask the user to restate what they already said.
   - Avoid speculative categories (no hallucination). If uncertain, ask explicitly: "Confirm whether X belongs in scope."
```

Preserve the "Defaults when interaction impossible" block and everything after
it unchanged.
