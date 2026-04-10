# Prompt Template: Benchmark Task Design

## Purpose

Create or revise exactly one benchmark task for one existing skill.

Use this prompt only for task design.
Do not run the full benchmark here.
Do validate the task locally with a temporary reference implementation.
The eventual benchmark run must leave reviewable trial artifacts behind.

## Inputs

- `SKILL_NAME`
- `VERIFIED_SKILL`
- `DATASET_FILE`
- `TASK_FILE`
- `RESULTS_FILE`
- `NUM_TRIALS` default `3`
- `INCLUDE_NO_SKILL` default `true`
- `ORCHESTRATOR_TIMEOUT_MINUTES` default `27`

## Default benchmark contract

Design for this run shape:

- one task
- one orchestrator subagent
- three arms: `original`, `verified`, `no-skill`
- `NUM_TRIALS = 3`
- one fresh worker subagent per trial
- workers may run in batches
- orchestrator timeout `27` minutes
- benchmark artifacts remain under `blind_trials/` after the run

## Core purpose

The benchmark must answer:

`Does this skill change agent behavior on a realistic Nim task in a way that can be scored deterministically?`

The benchmark is bad if it mainly measures:

- generic coding ability unrelated to the skill
- copying the prompt wording back into code
- obedience to an over-specified recipe

## Workflow

1. Read `VERIFIED_SKILL`, `DATASET_FILE`, `TASK_FILE` if it exists, and `RESULTS_FILE` if it exists.
2. Write one benchmark hypothesis in one sentence:
   `This task tests whether the skill changes agent behavior on X by measuring Y.`
3. Pick one realistic task where the skill should matter.
4. Before writing, separate:
   - task contract: what the worker is told
   - judge checklist: what is scored
   - validation notes: what you learned while proving the task works locally
5. Write `TASK_FILE`.
6. Write one binary judge checklist.
7. Check ceiling risk and leakage risk.
8. Validate locally with a temporary reference implementation.
9. Update `RESULTS_FILE`.

## What the task must contain

`TASK_FILE` should contain only the worker-facing contract:

- deliverables
- provided fixture or environment
- required observable behavior
- compile/run commands
- smoke assertions
- exact public API only if public API shape is itself the benchmark target
- exact style constraints only if style is itself the benchmark target
- exact module/decomposition constraints only if organization is itself the benchmark target

The task should read like a demanding but plausible user request, not like hidden judge notes.

## What the task must not contain

Do not put judge-only logic in the task body.

Unless the benchmark is explicitly about that exact convention, do not tell the worker:

- exact exported names
- exact internal helper names
- exact internal decomposition
- exact implementation strategy
- exact error-handling mechanism
- exact ownership-hook set
- exact callback-bridging pattern
- exact linker or pragma spelling
- exact anti-patterns the checklist will inspect

Do not turn the task into:

- a recipe for reproducing the verified skill
- a list of implementation hints copied from the skill
- a checklist disguised as requirements

## Skill-specific rule

Only specify exact conventions in the task when the benchmark is intentionally about those conventions.

Examples:

- For `nim-api-design`, exact public API shape may be central and can be specified.
- For `nim-style-guide`, exact style constraints may be central and can be specified.
- For `nim-code-organization`, module boundaries or export shape may be central and can be specified.
- For skills like bindings, wrappers, error handling, ownership, or docs, prefer specifying behavior, environment, and externally visible constraints, then let the worker choose the implementation.

If you are unsure whether something belongs in the task or only in the checklist:

- if a real user would naturally ask for it, it can belong in the task
- if it mainly exists to distinguish strong from weak solutions, it probably belongs in the checklist

## Judge checklist rules

Use only binary checks.

Allowed checklist evidence:

- compile success or failure
- runtime output
- runtime assertions
- direct code inspection for explicit objective properties or anti-patterns

Checklist items must be objectively scorable from the preserved trial artifacts.

Do not use:

- vague quality judgments
- subjective readability scoring
- architectural praise without an objective proxy
- checklist items that require guessing intent

If an inspection item is not clearly binary, rewrite it or remove it.

## Difficulty rules

Make the task hard by increasing decision pressure, not by over-instructing.

Good ways to raise difficulty:

- add one realistic fixture or environment constraint
- add one extra state transition
- add one extra module boundary
- add one realistic runtime or integration edge
- add one likely anti-pattern that weaker solutions often choose
- require a preserved artifact the judge can inspect later

Bad ways to raise difficulty:

- dumping more implementation detail into the task
- adding many tiny checklist bullets that all score the same thing
- making the task longer without creating more real choices

## Leakage check

Before finalizing the task, ask:

1. Could a strong worker pass mainly by transcribing the prompt?
2. Did I include solution ideas that came from the skill instead of from the external contract?
3. Would a no-skill worker be guided toward the same implementation by the task text alone?

If yes to any, the task is too tight and must be revised.

## Validation rules

You must validate the task locally before finalizing it.

Validation means:

- create a temporary reference implementation outside the benchmark deliverable path
- compile and run it with the exact commands from the task
- validate any relocation, fixture, or runtime edge that the task depends on
- use validation failures to improve the task wording

Do not copy validation-only discoveries into the task unless they are truly part of the external contract.
Put them in `RESULTS_FILE` if they matter for future maintainers.

## Hard rules

- design-only
- one task, one checklist
- keep the task plain
- keep the checklist binary
- design for real independent worker trials
- do not depend on orchestrator-written substitute outputs
- design tasks that still work when worker trials are launched in batches
- design tasks so preserved trial directories are enough for later code review
- do not prescribe the solution unless that prescription is the benchmark target
- do not mix worker instructions with judge-only reasoning
- do not create conflicting instructions between task body and checklist

## `RESULTS_FILE` minimum contents

- short task summary
- exact checklist
- current validation status
- short ceiling-risk note
- default run-shape note:
  `original, verified, no-skill; NUM_TRIALS=3; ORCHESTRATOR_TIMEOUT_MINUTES=27`

## Final self-check

Before saving, confirm all of these:

1. The task measures a behavior the skill is supposed to change.
2. The task body states the external contract, not the intended solution.
3. The checklist is binary and reviewable from preserved artifacts.
4. The task is realistic enough that the skill matters.
5. The task is open enough that different implementations are still possible.

## Reusability

Replace `{SKILL_NAME}`, `{VERIFIED_SKILL}`, `{DATASET_FILE}`, `{TASK_FILE}`, `{RESULTS_FILE}`, `{NUM_TRIALS}`, `{INCLUDE_NO_SKILL}`, and `{ORCHESTRATOR_TIMEOUT_MINUTES}`.
