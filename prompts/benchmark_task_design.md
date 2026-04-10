# Prompt Template: Benchmark Task Design

## Purpose

Create or revise exactly one benchmark task for one existing skill.

Use this prompt only for task design.
Do not run the full benchmark here.
Validate the task locally with a temporary reference implementation.

## Inputs

- `SKILL_NAME`
- `VERIFIED_SKILL`
- `DATASET_FILE`
- `TASK_FILE`

## Benchmark goal

The benchmark must answer:

`Does this skill change agent behavior on a realistic Nim task in a way that can be scored deterministically?`

The benchmark is bad if it mainly measures:

- generic coding ability unrelated to the skill
- copying the prompt wording back into code
- obedience to an over-specified recipe

## Task file format

`TASK_FILE` must contain exactly these sections in this order:

1. `# Task`
2. `## Deliverables`
3. `## Inputs and Fixtures`
4. `## Required Behavior`
5. `## Required Commands`
6. `## Judge Checklist`

Meaning:

- Sections 1 to 5 are worker-facing.
- `## Judge Checklist` is scorer-facing.
- The benchmark runner must copy only the sections before `## Judge Checklist` into each trial as `TASK.md`.
- The benchmark runner must use only `## Judge Checklist` for scoring.

Do not mix scorer-only rules into the worker-facing sections.

## Workflow

1. Read `VERIFIED_SKILL`, `DATASET_FILE`, and `TASK_FILE` if it exists.
2. Write one benchmark hypothesis in one sentence:
   `This task tests whether the skill changes agent behavior on X by measuring Y.`
3. Pick one realistic task where the skill should matter.
4. Write the worker-facing sections.
5. Write one binary `## Judge Checklist`.
6. Check for leakage and ceiling risk.
7. Validate locally with a temporary reference implementation.
8. Update `TASK_FILE`.

## Worker-facing sections

Keep sections 1 to 5 plain and direct.

They may include:

- deliverables
- provided fixture or environment
- required observable behavior
- compile or run commands
- smoke assertions
- exact public API only if API shape is the benchmark target
- exact style constraints only if style is the benchmark target
- exact module boundaries only if organization is the benchmark target

They must not include judge-only logic.

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

If a real user would naturally ask for it, it can belong in the worker-facing sections.
If it mainly exists to distinguish strong from weak solutions, it belongs in the checklist.

## Trial-local execution rules

Every benchmark task must be runnable from a fresh trial directory.

That means:

- every command in `## Required Commands` must be valid when run from the trial cwd
- every worker-visible file path must be relative to that trial directory
- fixture files must be referenced as staged local paths such as `fixtures/...`
- output files must be written only inside the trial directory
- do not make the worker read from repo-root paths such as `blind_trials/...`
- do not make two trials write to the same path

If the task needs committed fixture files from the repo, the runner should stage copies into the trial directory before the worker starts.
Write the task as if the staged files are already present.

## Judge checklist rules

Use only binary checks.

Allowed evidence:

- compile success or failure
- runtime output
- runtime assertions
- direct code inspection for explicit objective properties or anti-patterns

Checklist items must be reviewable from that trial directory alone.

Do not use:

- vague quality judgments
- subjective readability scoring
- praise without an objective proxy
- anything that requires guessing intent

## Difficulty rules

Make the task harder by increasing decision pressure, not by adding solution hints.

Good ways to raise difficulty:

- add one realistic fixture or environment constraint
- add one extra state transition
- add one extra module boundary
- add one realistic runtime edge
- add one likely anti-pattern that weaker solutions often choose

Bad ways to raise difficulty:

- dumping implementation detail into the worker-facing task
- turning the task into a recipe
- adding many checklist items that all score the same thing

## Leakage check

Before saving, ask:

1. Could a strong worker pass mainly by transcribing the task text?
2. Did I copy solution ideas from the skill into the worker-facing task?
3. Would a no-skill worker be pushed toward the same implementation by the task text alone?

If yes to any, the task is too tight and must be revised.

## Validation rules

Validate the task locally before finalizing it:

- create a temporary reference implementation outside the benchmark deliverable path
- stage any needed fixtures into that temporary directory
- run the commands from that directory, not from the repo root
- run the exact commands from `## Required Commands`
- validate any relocation, fixture, or runtime edge the task depends on
- use validation failures to improve the task wording

Do not commit validation notes or benchmark result files.
The later benchmark run should keep only isolated failure samples in the dataset.

## Hard rules

- design only
- one task file
- one binary checklist
- worker-facing sections and judge checklist must not conflict
- do not prescribe the solution unless that prescription is the benchmark target
- design for fresh independent worker trials
- design so one trial directory is enough for scoring and review

## Final self-check

Before saving, confirm:

1. The task measures a behavior the skill is supposed to change.
2. The worker-facing task states the external contract, not the intended solution.
3. The checklist is binary and reviewable.
4. The task is realistic enough that the skill matters.
5. Different implementations are still possible.

## Reusability

Replace `{SKILL_NAME}`, `{VERIFIED_SKILL}`, `{DATASET_FILE}`, and `{TASK_FILE}`.
