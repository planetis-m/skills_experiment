# Prompt Template: Benchmark Task Design

## Purpose
Create or revise one benchmark task.

Use this prompt only for task design.
Do not run the benchmark here.

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

## Workflow

1. Read `VERIFIED_SKILL`, `DATASET_FILE`, `TASK_FILE` if it exists, and `RESULTS_FILE` if it exists.
2. Pick one benchmark goal.
   The task must answer:
   `Does the skill change agent behavior on a realistic task in a way the judge can score?`
3. Design one task that is:
   - small enough to repeat
   - open enough that the skill still matters
   - deterministic enough for binary scoring
4. Fix only what the judge needs to score:
   - runtime behavior
   - fake helpers or environment
   - compile/run commands
   - smoke run
5. Leave most names and decomposition open unless they are central to the skill.
6. Write one binary checklist using only:
   - compile success or failure
   - runtime output or assertions
   - direct code inspection for explicit anti-patterns
7. Check ceiling risk.
   - too tight: workers can transcribe the task
   - too weak: no-skill likely scores about the same
8. Validate the task locally with a temporary reference implementation.
9. Update `TASK_FILE` and `RESULTS_FILE`.

## Hard rules

- design-only
- one task, one checklist
- keep the task plain
- keep the checklist binary
- design for real independent worker trials
- do not depend on orchestrator-written substitute outputs
- design tasks that still work when worker trials are launched in batches

## `RESULTS_FILE` minimum contents

- short task summary
- exact checklist
- current validation status
- short ceiling-risk note
- default run-shape note:
  `original, verified, no-skill; NUM_TRIALS=3; ORCHESTRATOR_TIMEOUT_MINUTES=27`

## Reusability
Replace `{SKILL_NAME}`, `{VERIFIED_SKILL}`, `{DATASET_FILE}`, `{TASK_FILE}`, `{RESULTS_FILE}`, `{NUM_TRIALS}`, `{INCLUDE_NO_SKILL}`, and `{ORCHESTRATOR_TIMEOUT_MINUTES}`.
