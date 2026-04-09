# Prompt Template: Blind Benchmark

## Purpose
Run an existing benchmark task.

Use this prompt only when the task file and scoring checklist already exist.
Do not redesign the task here.

## Inputs
- `ORIGINAL_SKILL`: path to `original_skills/{SKILL_NAME}/SKILL.md`
- `VERIFIED_SKILL`: path to `skills/{SKILL_NAME}/SKILL.md`
- `TASK_FILE`: path to an existing task file under `blind_trials/`
- `NUM_TRIALS`: trials per arm, default `3`
- `INCLUDE_NO_SKILL`: whether to include the no-skill control arm, default `true`

## What this prompt does

It runs one benchmark with these arms:
- original skill
- verified skill
- no-skill control, when `INCLUDE_NO_SKILL` is `true`

The benchmark is one run with multiple arms.
It is not three separate benchmark campaigns.

## Workflow

1. Read the inputs.
   Read `TASK_FILE`, `ORIGINAL_SKILL`, and `VERIFIED_SKILL`.

2. Use one orchestrator.
   Spawn exactly one orchestrator subagent for the whole benchmark run.
   The orchestrator is responsible for:
   - preparing trial directories
   - keeping the hidden mapping
   - spawning worker trials
   - waiting for all trial outcomes
   - scoring every trial
   - unblinding after scoring
   - deleting temporary benchmark artifacts
   - returning one final summary

3. Prepare trial directories.
   Create one trial directory per run.
   Each directory must contain only:
   - `TASK.md`
   - `subject_solution.nim` destination
   - `SKILL.md` only for skill-guided arms

   Do not put hidden mapping, group labels, or summary files in the trial directory.

4. Spawn worker trials.
   Trial count:
   - `2 * NUM_TRIALS` when `INCLUDE_NO_SKILL` is `false`
   - `3 * NUM_TRIALS` when `INCLUDE_NO_SKILL` is `true`

   Use the same model, tool policy, sandbox mode, and timeout for every worker.

   Worker instruction for skill-guided arms:

   ```text
   Read ./SKILL.md and ./TASK.md.
   Write the required solution to ./subject_solution.nim.
   Run exactly the commands required by TASK.md.
   If a command fails, fix the code and retry within this trial directory.
   After the trial is finished, return exactly ANNOUNCE_SKIP.
   ```

   Worker instruction for no-skill control:

   ```text
   Read ./TASK.md.
   Write the required solution to ./subject_solution.nim.
   Run exactly the commands required by TASK.md.
   If a command fails, fix the code and retry within this trial directory.
   After the trial is finished, return exactly ANNOUNCE_SKIP.
   ```

5. Wait for all trials.
   Do not score or summarize early.
   Every trial must reach one terminal state:
   - success
   - error
   - timeout

6. Score every trial.
   The orchestrator scores all trials itself using only the checklist in `TASK_FILE`.
   For each trial:
   - check compile/run results first
   - score every checklist item exactly as written
   - write one `verdict.json`

7. Unblind after scoring.
   After every trial has a verdict:
   - reveal which runs were original, verified, and no-skill
   - compare arm results
   - collect concrete mistakes made by workers

8. Write one benchmark summary.
   Write one unblinded results file under `blind_trials/`.
   Include:
   - per-arm scores
   - verified vs original
   - verified vs no-skill, when present
   - original vs no-skill, when present
   - concrete mistakes made by workers

## Interpretation rules

- If verified beats original and no-skill, the verified skill is adding value.
- If verified beats original but not no-skill, the verified skill may not be adding meaningful value.
- If all arms perform similarly well, the task may be too easy or too specified.
- If all arms fail in the same way, treat that as a task or model-default issue first.

## Hard rules

- one orchestrator per benchmark run
- use an existing task file; do not redesign the task here
- one fresh worker subagent per trial
- no group labels in worker-visible context
- no hidden mapping in trial directories
- no final summary while any trial is still pending
- include a no-skill control arm by default unless there is a clear reason not to

## Reusability
Replace `{SKILL_NAME}`, `{ORIGINAL_SKILL}`, `{VERIFIED_SKILL}`, `{TASK_FILE}`, `{NUM_TRIALS}`, and `{INCLUDE_NO_SKILL}` with the target values.
