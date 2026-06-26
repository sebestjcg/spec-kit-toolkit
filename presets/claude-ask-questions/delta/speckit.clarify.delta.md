# Delta: speckit.clarify → AskUserQuestion rendering

This is a **semantic patch**, not a line patch. It describes the *only* changes
this preset makes to the core `speckit.clarify` command. The generator
(`scripts/generate.sh`) hands the current core command plus this file to
`claude -p` and asks it to apply exactly these transforms and nothing else.

## Global rules (apply to every transform below)

- Change **only** the blocks described here. Every other character of the core
  command — front matter, scripts, handoffs, headings, ordering, whitespace,
  the ambiguity taxonomy, the 5-question cap, the spec-integration rules,
  pre/post-execution hook sections — MUST be preserved byte-for-byte.
- Match the target blocks by their **meaning / anchor wording**, not by line
  number. Core may have shifted lines, reworded neighbours, or added sections;
  locate the block by the quoted anchor text and replace it in place.
- If a target block is **not present** in the current core (upstream already
  changed it), skip that transform and leave the surrounding text untouched.
  Never invent a place to insert it.
- Output the complete merged command file and nothing else (no commentary, no
  code fences).

## Transform 1 — Multiple-choice questioning block

**Locate** the block inside the sequential questioning loop that, for
multiple-choice questions, tells the agent to surface a recommended option as
`**Recommended:** Option [X]` and then "render all options as a Markdown table"
with an `| Option | Description |` table and a follow-up sentence beginning
"After the table, add: `You can reply with the option letter ...`".

**Replace** that entire "render as Markdown table + reply with letter"
instruction (keep the preceding "Analyze all options / determine the most
suitable option" bullet) with:

```
       - Use the `AskUserQuestion` tool to present the question as a native structured picker:
          - `question`: the clarification question text, prefixed with your recommendation in the form `"Recommended: Option [X] — <1-2 sentence reasoning>\n\n<question text>"`.
          - `options[]`: an array of `{label, description}` objects. Place the **recommended option first** and prefix its `description` with `Recommended — <reasoning>.` Build each option as `{label: "<A|B|C|...>", description: "<option description>"}`.
          - Append a final option `{label: "Short", description: "Provide my own short answer (≤5 words)"}` to preserve the free-form escape hatch.
          - `multiSelect`: `false`.
       - If the user selects the "Short" option, ask a follow-up free-text question constrained to ≤5 words.
```

## Transform 2 — Short-answer questioning block

**Locate** the "For short-answer style (no meaningful discrete options)" block
that tells the agent to provide a `**Suggested:** <answer>` and then output
`Format: Short answer (<=5 words). You can accept the suggestion by saying
"yes" ...`.

**Replace** that block with:

```
     - For short‑answer style (no meaningful discrete options):
       - Determine your **suggested answer** based on best practices and context.
       - Use the `AskUserQuestion` tool:
          - `question`: `"Suggested: <your proposed answer> — <brief reasoning>\n\n<question text>\nFormat: Short answer (≤5 words)."`
          - `options[]`: `[{label: "Accept suggestion", description: "Use the suggested answer above"}, {label: "Custom", description: "Provide my own short answer (≤5 words)"}]`.
          - `multiSelect`: `false`.
       - If the user selects "Custom", ask a follow-up free-text question constrained to ≤5 words.
```

## Transform 3 — "After the user answers" acceptance check

**Locate** the bullet under "After the user answers:" that reads roughly:
`If the user replies with "yes", "recommended", or "suggested", use your
previously stated recommendation/suggestion as the answer.`

**Replace** only that single bullet with:

```
       - If the user accepted the recommendation/suggestion option, use your previously stated recommendation/suggestion as the answer.
```

Leave the remaining bullets in that block ("Otherwise, validate the answer…",
"If ambiguous…", "Once satisfactory…") unchanged.
