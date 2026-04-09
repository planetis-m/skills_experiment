# Prompt Template: Blind Benchmark

## Purpose
Run one existing benchmark task.

Use this prompt only when the task file and checklist already exist.
Do not redesign the task here.

## Inputs
- `ORIGINAL_SKILL`
- `VERIFIED_SKILL`
- `TASK_FILE`
- `NUM_TRIALS` default `3`
- `INCLUDE_NO_SKILL` default `true`
- `ORCHESTRATOR_TIMEOUT_MINUTES` default `27`

## Default benchmark contract

- one benchmark run
- one orchestrator subagent
- three arms: `original`, `verified`, `no-skill`
- `NUM_TRIALS = 3`
- one fresh worker subagent per trial
- workers may be launched in batches
- orchestrator timeout `27` minutes

If fresh independent worker trials are unavailable, the run is invalid and must stop.
Do not simulate missing trials.

## Workflow

1. Read `TASK_FILE`, `ORIGINAL_SKILL`, and `VERIFIED_SKILL`.
2. Spawn one orchestrator subagent for the full run.
3. The orchestrator creates one benchmark artifact directory for the run under `blind_trials/`.
4. Inside that directory, the orchestrator creates one trial directory per run.
   Each trial directory contains only:
   - `TASK.md`
   - `subject_solution.nim`
   - `SKILL.md` only for skill-guided arms
   - command outputs needed for scoring
5. The orchestrator spawns fresh worker trials.
   Trial count:
   - `2 * NUM_TRIALS` without no-skill
   - `3 * NUM_TRIALS` with no-skill
6. Workers write `subject_solution.nim` and run exactly the commands required by `TASK.md`.
7. The orchestrator waits for every trial to finish.
8. The orchestrator scores every trial using only the checklist in `TASK_FILE`.
9. After scoring all trials, the orchestrator unblinds the mapping and writes one unblinded results file under `blind_trials/`.
10. The orchestrator keeps the benchmark artifact directory intact after the run. Do not delete trial directories.

## Worker instructions

Skill-guided worker:

```text
Read ./SKILL.md and ./TASK.md.
Write the required solution to ./subject_solution.nim.
Run exactly the commands required by TASK.md.
If a command fails, fix the code and retry within this trial directory.
After the trial is finished, return exactly ANNOUNCE_SKIP.
```

No-skill worker:

```text
Read ./TASK.md.
Write the required solution to ./subject_solution.nim.
Run exactly the commands required by TASK.md.
If a command fails, fix the code and retry within this trial directory.
After the trial is finished, return exactly ANNOUNCE_SKIP.
```

## Invalid-run rules

Mark the run invalid and stop if:
- the orchestrator cannot be spawned
- fresh independent worker trials cannot be created
- any trial output was authored by the orchestrator
- any arm uses simulated or hand-written substitute outputs instead of real worker trials

Invalid runs write a short failure report, not benchmark scores.

## Hard rules

- one orchestrator subagent per benchmark run
- use an existing task file
- do not redesign the task here
- one fresh worker subagent per trial
- workers may run in batches
- keep all trial directories after the run
- no group labels in worker-visible context
- no hidden mapping in trial directories
- do not let the orchestrator author trial solutions
- do not summarize before all trials reach a terminal state

## Required artifacts

Keep these artifacts for review:

- one benchmark artifact directory under `blind_trials/`
- one trial directory per worker
- every `subject_solution.nim`
- the exact `TASK.md` each worker saw
- `SKILL.md` for skill-guided arms
- command outputs needed for scoring
- one unblinded results file

## Interpretation

- verified > original and no-skill: verified skill adds value
- verified > original but not no-skill: weak skill signal
- all arms similar and strong: task may be too easy or too specified
- all arms fail the same way: likely task or model-default issue first

## Reusability
Replace `{SKILL_NAME}`, `{ORIGINAL_SKILL}`, `{VERIFIED_SKILL}`, `{TASK_FILE}`, `{NUM_TRIALS}`, `{INCLUDE_NO_SKILL}`, and `{ORCHESTRATOR_TIMEOUT_MINUTES}`.
