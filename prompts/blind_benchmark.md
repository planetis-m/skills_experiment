# Prompt Template: Blind Benchmark

## Purpose
Compare the original and verified skill on the same task without knowing which skill produced which result until scoring is complete.

## Inputs
- `ORIGINAL_SKILL`: path to `original_skills/{SKILL_NAME}/SKILL.md`
- `VERIFIED_SKILL`: path to `skills/{SKILL_NAME}/SKILL.md`
- `TASK_SPEC`: task prompt with exact requirements
- `NUM_TRIALS`: trials per group, default `3`

## Instructions

### Step 1: Prepare the blind run

1. Create or reuse `blind_trials/`.
2. Copy one skill to `blind_trials/group_x_skill.md`.
3. Copy the other skill to `blind_trials/group_y_skill.md`.
4. Do not write the X/Y mapping to disk before scoring is finished.
5. Write `blind_trials/task.txt` from `{TASK_SPEC}`.
6. Make sure `task.txt` includes a short binary rubric for scoring.
7. Create isolated output directories: `blind_trials/A1..A{NUM_TRIALS}` and `blind_trials/B1..B{NUM_TRIALS}`.

### Rubric rules

The rubric must be:
- binary per item: pass or fail
- directly observable from compile output, runtime output, or the generated code
- consistent with one chosen convention for the task
- limited to checks the agent can actually run in the repo

For design-oriented skills, prefer tasks that are large enough for the judge to inspect anti-patterns in the generated code.
Examples:
- unnecessary local `try/except` wrappers
- ad-hoc intermediate result types
- pointless exception translation
- mixed conventions inside one implementation

Do not include rubric items that depend on unavailable tools or environments.

### Step 2: Spawn generators

Spawn `2 * NUM_TRIALS` generator agents.

For each agent:
- provide the assigned skill file
- provide the same `task.txt`
- tell it to write to one absolute output path inside its own trial directory
- tell it to compile or run the code exactly as the task requires

Group A reads `group_x_skill.md`.
Group B reads `group_y_skill.md`.

### Step 3: Score blindly

Do not unblind yet.

For each trial:
1. Check `COMPILE` first.
2. Score every rubric item from `task.txt` exactly as written.
3. Record the result in `verdict.json`.
4. Use the same rubric for every trial in both groups.

If the task is refcounted or ownership-related, choose one convention up front and score only against that convention.
If the task is style-sensitive, the judge may score explicit anti-pattern checks by reading the generated code.

### Step 4: Aggregate and unblind

After every trial has a verdict:
1. Aggregate results by group.
2. Only then reveal which group used which skill.
3. Write `benchmarking_results.md` with:
   - blind results
   - unblinded results
   - group aggregates
   - short analysis
   - a note that small `n` is not statistically strong

### Step 5: Feed back

If the benchmark exposes real weaknesses:
1. Note the concrete failure modes.
2. Feed those failures back into Phase 1 as new or corrected claims.
3. Do not rewrite the skill inside the benchmark step itself.

## Key rules

- keep the task identical for both groups
- keep scoring blind until all verdicts are written
- use absolute output paths for generator agents
- benchmark one default implementation path at a time
- do not mix incompatible conventions inside one task

## Reusability
Replace `{SKILL_NAME}`, `{ORIGINAL_SKILL}`, `{VERIFIED_SKILL}`, `{TASK_SPEC}`, and `{NUM_TRIALS}` with the target values.
