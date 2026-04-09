# Prompt Template: Benchmark Task Design

## Purpose
Create or revise a benchmark task.

Use this prompt only when you are designing the task and checklist.
Do not run the benchmark here.

## Inputs
- `SKILL_NAME`: skill directory name
- `VERIFIED_SKILL`: path to `skills/{SKILL_NAME}/SKILL.md`
- `DATASET_FILE`: path to `datasets/{SKILL_NAME}/dataset.json`
- `TASK_FILE`: path to `blind_trials/task_{name}.txt`
- `RESULTS_FILE`: path to `blind_trials/benchmarking_results_{name}.md`

## What this prompt does

It produces two files:
- one task file
- one factual benchmark-status file

It does not run the blind benchmark.

## Workflow

1. Read the current materials.
   Read:
   - `VERIFIED_SKILL`
   - `DATASET_FILE`
   - `TASK_FILE`, if it exists
   - `RESULTS_FILE`, if it exists

2. Pick one benchmark goal.
   The task must answer one question:
   `Does the skill change agent behavior on a realistic task in a way the judge can score?`

3. Design one task.
   The task should be:
   - small enough to run repeatedly
   - open enough that the skill still matters
   - deterministic enough that checklist items are binary

4. Fix only what is necessary.
   Usually fix:
   - domain
   - fake environment or helper behavior
   - observable runtime behavior
   - compile/run command
   - smoke run

   Usually leave open:
   - helper names
   - internal decomposition
   - most proc names, unless they are central to the skill

5. Write one checklist.
   The checklist must use only:
   - compile success or failure
   - runtime output or assertions
   - direct code inspection for explicit anti-patterns

   Every item must be binary.

6. Check ceiling risk.
   The task is too tight if workers can mostly transcribe the prompt.
   The task is too weak if a no-skill run would likely perform about as well as the skill-guided runs.

7. Validate the task locally.
   Write a temporary reference implementation.
   Run the exact commands required by the task.
   Confirm the smoke run passes.

8. Write the output files.
   Update `TASK_FILE`.
   Update `RESULTS_FILE` with:
   - short task summary
   - exact checklist
   - current validation status
   - short ceiling-risk note

## Design rules

- Prefer one task, one checklist, one scoring convention.
- Prefer behavior and code shape over trivia.
- Do not score hidden implementation details with no benchmark value.
- Do not score syntax preferences when both forms are equivalent for the benchmark goal.
- If both skills would obviously converge, loosen the task before running the benchmark.

## Hard rules

- use this prompt only for task design or revision
- do not run the blind benchmark here
- keep the task plain and direct
- keep the checklist binary
- keep `RESULTS_FILE` factual

## Reusability
Replace `{SKILL_NAME}`, `{VERIFIED_SKILL}`, `{DATASET_FILE}`, `{TASK_FILE}`, and `{RESULTS_FILE}` with the target values.
