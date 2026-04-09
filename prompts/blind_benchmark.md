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
- `ORCHESTRATOR_TIMEOUT_MINUTES`: timeout for the whole benchmark run, default `27`

## What this prompt does

It runs one benchmark with these arms:
- original skill
- verified skill
- no-skill control, when `INCLUDE_NO_SKILL` is `true`

The benchmark is one run with multiple arms.
It is not three separate benchmark campaigns.

If the environment cannot create fresh independent worker trials, do not improvise a replacement.
Stop and report that the benchmark run is invalid.

## Workflow

1. Read the inputs.
   Read `TASK_FILE`, `ORIGINAL_SKILL`, and `VERIFIED_SKILL`.

2. Use one orchestrator.
   Spawn exactly one orchestrator subagent for the whole benchmark run.
   Set the orchestrator timeout to `ORCHESTRATOR_TIMEOUT_MINUTES`.
   Default to `27`.
   The orchestrator is responsible for:
   - preparing trial directories
   - keeping the hidden mapping
   - spawning worker trials
   - waiting for all trial outcomes
   - scoring every trial
   - unblinding after scoring
   - deleting temporary benchmark artifacts
   - returning one final summary

   If the environment cannot spawn the orchestrator or cannot later spawn fresh worker trials, stop here.
   Do not continue with a partial benchmark.

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

   Use the same model, tool policy, and sandbox mode for every worker.

   Each trial must be run by a fresh independent worker.
   Do not reuse one worker across trials.
   Do not let the orchestrator write benchmark solutions itself.
   Do not simulate a no-skill arm by deliberately writing bad code.

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

   If fresh independent workers cannot be created, stop the benchmark and report:
   `INVALID BENCHMARK RUN: independent worker trials were not available.`
   Do not score the run.
   Do not write synthetic per-arm results.

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

   If any arm was not produced by fresh independent workers, the whole run is invalid.
   Do not score partial or synthetic results as a benchmark outcome.

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

   If the run was invalid, write a short failure report instead of benchmark scores.
   State the exact blocker and stop.

## Interpretation rules

- If verified beats original and no-skill, the verified skill is adding value.
- If verified beats original but not no-skill, the verified skill may not be adding meaningful value.
- If all arms perform similarly well, the task may be too easy or too specified.
- If all arms fail in the same way, treat that as a task or model-default issue first.

## Hard rules

- one orchestrator per benchmark run
- orchestrator timeout must be about 27 minutes; default `27`
- use an existing task file; do not redesign the task here
- one fresh worker subagent per trial
- no group labels in worker-visible context
- no hidden mapping in trial directories
- no final summary while any trial is still pending
- include a no-skill control arm by default unless there is a clear reason not to
- do not let the orchestrator author trial solutions
- do not replace missing worker trials with simulated or hand-written outputs
- if independent worker trials are unavailable, mark the run invalid and stop

## Reusability
Replace `{SKILL_NAME}`, `{ORIGINAL_SKILL}`, `{VERIFIED_SKILL}`, `{TASK_FILE}`, `{NUM_TRIALS}`, `{INCLUDE_NO_SKILL}`, and `{ORCHESTRATOR_TIMEOUT_MINUTES}` with the target values.
