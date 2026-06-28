/superpowers:brainstorming speckit has a few commands like:

/speckit-constitution	speckit-constitution	Create or update project governing principles and development guidelines
/speckit-specify	speckit-specify	Define what you want to build (requirements and user stories)
/speckit-clarify	speckit-clarify	Clarify underspecified areas (recommended before /speckit.plan; formerly /quizme)
/speckit-checklist	speckit-checklist	Generate custom quality checklists that validate requirements completeness, clarity, and consistency (like "unit tests for English")
/speckit-plan	speckit-plan	Create technical implementation plans with your chosen tech stack
/speckit-tasks	speckit-tasks	Generate actionable task lists for implementation
/speckit-analyze	speckit-analyze	Cross-artifact consistency & coverage analysis (run after /speckit.tasks, before /speckit.implement)
/speckit-implement	speckit-implement	Execute all tasks to build the feature according to the plan

For my workflow there are a few missing commands that i want to write an extension for. Check @documentation/reference/spec-kit-docs-extensions-presets-repomix.xml for the context for writing a new speckit extension. 

For my workflow, I want to create these commands:


| Command                      | Prompt                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   |
|------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| /speckit-tick-checklist      | Read the review and acceptance checklist, and check off each item in the checklist if the feature spec meets the criteria. Leave it empty if it does not.                                                                                                                                                                                                                                                                                                                                                                                                |
| /speckit-resolve-checklist   | Resolve [] check the @documentation/requirements/ first to answer the checklists, then check the source code to find the answer, if not found then ask the AskUserQuestion Tool to ask me questions in batches of 5 questions                                                                                                                                                                                                                                                                                                                            |
| /speckit-validate-plan       | Now I want you to go and audit the implementation plan and the implementation detail files. Read through it with an eye on determining whether or not there is a sequence of tasks that you need to be doing that are obvious from reading this. Because I don't know if there's enough here. For example, when I look at the core implementation, it would be useful to reference the appropriate places in the implementation details where it can find the information as it walks through each step in the core implementation or in the refinement. |
| /speckit-validate-testing    | Ensure the plan explicitly requires: 1) Implementing features using Domain-Driven Design (DDD) principles, following a red-green-refactor test-driven development work-flow. 2) After each feature is implemented, using Playwright to verify the feature works correctly end-to-end.                                                                                                                                                                                                                                                                    |
| /speckit-validate-tasks      | Ensure the tasks explicitly requires: 1) Implementing features using Domain-Driven Design (DDD) principles, following a red-green-refactor test-driven development work flow. 2) After each feature is implemented, using Playwright to verify the feature works correctly end-to-end.                                                                                                                                                                                                                                                                   |
| /speckit-research            | Decision gate (do this first, in writing)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                

The failure mode you are explicitly avoiding is untargeted, general-purpose library scanning ("tell me about library X") that returns broad summaries instead of answers that unblock a specific implementation step.

1. Read the inputs — the implementation plan, plan.md, research.md, data-model.md, quickstart.md, and any referenced specs — before deciding.
2. Apply the load-bearing test to every candidate research item: "Does answering this resolve a specific implementation decision I am currently unsure about?" If you cannot phrase it as one targeted question with a verifiable answer, it is too broad — it belongs in Path B enumeration, not a task.
3. State your routing decision explicitly — "Path A" or "Path B" — with one sentence of justification grounded in what you read.

Calibration:

- NARROW → Path A. One library/API surface with bounded, version-specific unknowns you can already name. E.g. "Confirm the invocation signature and breaking changes for d3-scale v4 sequential color scales for our legend"; "Verify how litellm v1.x streams completions and passes a system prompt for /ai/sql."
- BROAD or AMBIGUOUS → Path B. A whole subsystem, multiple interacting libraries, or a vague directive where naive fan-out would just scan each library in general. E.g. "Research everything for the map legend + district-name feature" (renderer, geo/projection, label collision, i18n, color scale); "Look into the reporting/AI pipeline" (LLM client, prompt design, banding, validation at once).
- Rule of thumb / tie-breaker: if it reduces to one library and you can name the concrete unknowns, go A. Otherwise go B. When genuinely on the fence, prefer B — enumerating questions first is cheap insurance against unfocused output.

Edge cases — handle explicitly, don't default:
- Mixed scope. If part of the subject is well-scoped and part is broad, split it: spawn Path A tasks for the targeted questions, run Path B enumeration on the broad remainder. Say you are doing this.
- Scope grows mid-decision. If, while reading, the subject turns out larger or fuzzier than it looked, downgrade the affected portion to Path B rather than forcing premature tasks.
- No genuine research needed. If nothing meets the load-bearing test, do not spawn tasks. Say so and stop.
- Too many questions. If enumeration yields an unwieldy list, prioritize by implementation risk and impact, research the top questions in parallel, and list the deferred ones explicitly.

Path A — Well-scoped: research directly in parallel

1. Go through the plan and implementation details for areas that would benefit from research, prioritizing libraries/APIs that are rapidly changing or version-sensitive.
2. For each, pin the exact version(s) this app will use and record them in research.md (add/update the relevant section) before researching.
3. Spawn one parallel research task per area, each scoped to a single concrete question. Every task names the library, the pinned version, and the precise unknown to resolve via the web. Never spawn a task whose mandate is "study library X."

Path B — Broad/ambiguous: enumerate first, then fan out

Do NOT spawn anything yet. The trap is one task per library, each researching that library in general.

1. Break the work down: write an explicit list of the concrete implementation tasks you are unsure of. Convert each into a single targeted question tied to a real implementation step and to a named library + pinned version, phrased so a correct answer directly unblocks something you will write. Reject any "learn about library X" entry — rewrite it as the specific thing you need to do with it.
2. Record the targeted version(s) for each question in research.md.
3. Only then spawn the tasks — exactly one per enumerated question — to run in parallel.

Requirements for every research task (both paths)

- One specific, answerable, version-pinned question tied to a real implementation decision, with the library and version named in the task. If a task can't be reduced to a checkable answer, split or sharpen it first.
- Web research, official sources preferred — docs, changelogs, release notes for the pinned version.
- Each task returns: the direct answer; the source(s)/links; any version-specific caveats or breaking changes relative to our pinned version; and a minimal code/config snippet when the answer is load-bearing.
- After results return: reconcile findings into research.md, keeping the recorded versions and the resolved decision/rationale per area. Flag anything still unresolved, any contradiction between sources, and any new, more specific follow-up question — don't paper over them.|