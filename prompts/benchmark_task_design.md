# Prompt Template: Benchmark Task Design

## Purpose
Create or refine a benchmark task that actually tests whether a skill improves generated Nim code.

Use this prompt before running `prompts/blind_benchmark.md`.

## Inputs
- `SKILL_NAME`: skill directory name
- `VERIFIED_SKILL`: path to `skills/{SKILL_NAME}/SKILL.md`
- `DATASET_FILE`: path to `datasets/{SKILL_NAME}/dataset.json`
- `TASK_FILE`: path to `blind_trials/task_{name}.txt`
- `RESULTS_FILE`: path to `benchmarking_results_{name}.md`

## Instructions

### Existing benchmark handling

If `TASK_FILE` already exists:
1. Read it first.
2. Read `RESULTS_FILE` if it exists.
3. Keep what is still useful.
4. Remove task details that force the same solution shape across all runs.
5. Make targeted edits instead of starting over unless the task is clearly unusable.

If `TASK_FILE` does not exist:
1. Read `VERIFIED_SKILL`.
2. Read `DATASET_FILE`.
3. Design one benchmark task from the verified claims and benchmark gaps.

### What the benchmark must test

The benchmark must test skill effectiveness, not task-following on a fully specified implementation.

Include:
- decisions the skill is supposed to improve
- failure modes already seen in benchmarks or review
- benchmark-only claims from `needs_stronger_tests`
- code-shape checks that matter to library quality

Exclude:
- low-value details that do not reflect skill quality
- style preferences with no correctness or API-quality impact
- checks that can be gamed by copying the task wording
- checks the judge cannot score reliably

### Pick one task shape

Write one task that is:
- small enough to run and inspect quickly
- open enough that the skill still has room to matter
- deterministic enough that every rubric item is binary

Good benchmark tasks usually fix:
- the domain
- the fake environment or helper behavior
- the observable runtime behavior
- the compile/run command

Good benchmark tasks usually do **not** fix:
- every proc name
- every helper name
- every internal decomposition
- every accessor or wrapper unless the skill is specifically about that exact surface

### Use the right level of specification

If the task is over-specified:
- remove exact proc names that are not central to the skill
- remove exact helper structure
- move anti-patterns out of the task body and into the judge rubric
- keep only the observable contract fixed

If the task is under-specified:
- add fixed seed data
- add fixed smoke assertions
- add a required compile/run command
- add a short surface map comment if the judge needs help identifying chosen names

### Rubric rules

The rubric must:
- use binary checks only
- score only things the orchestrator can actually inspect
- prefer behavior and API quality over trivia
- avoid duplicate checks
- avoid one noisy item dominating the whole outcome

Use these evidence sources only:
- compile success or failure
- runtime output or assertions
- direct code inspection for explicit anti-patterns

Do not score:
- hidden implementation details with no public effect
- private-vs-public helper details unless they create a second public API path
- syntax preferences when both forms are equivalent for the benchmark goal

### Anti-ceiling checks

Before writing the final task, check for ceiling-effect risk.

A task is too tight if:
- most exported proc names are fixed
- the public API roles are fully enumerated
- the internal helper breakdown is already implied by the prompt
- workers can pass by transcribing the spec instead of making design choices

If the task is too tight, loosen one of these:
- number of fixed public operations
- exact proc names
- exact helper structure
- exact internal representation

Keep runtime behavior fixed while loosening API-shape decisions.

### Validation

After writing `TASK_FILE`:
1. Write a temporary reference implementation.
2. Run the exact compile/run command required by the task.
3. Confirm the smoke run passes.
4. Check that each rubric item is still judgeable from code, compile output, or runtime output.

If the temporary implementation fails because the task is ambiguous, fix the task text before finishing.

### Output files

Write or update `TASK_FILE`.

Write or update `RESULTS_FILE` with:
- a short task summary
- the exact judge checklist
- current validation status

Keep `RESULTS_FILE` factual. Do not include benchmark history that no longer helps judge the current task.

## Output requirements

`TASK_FILE` must:
- be plain and direct
- use exact names only where truly necessary
- include one fixed compile/run command
- include one fixed smoke run
- end with the judge checklist

`RESULTS_FILE` must:
- summarize what the task tests
- repeat the exact judge checklist
- state whether the task was locally validated

## Reusability
Replace `{SKILL_NAME}`, `{VERIFIED_SKILL}`, `{DATASET_FILE}`, `{TASK_FILE}`, and `{RESULTS_FILE}` with the target values.
