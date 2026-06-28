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
