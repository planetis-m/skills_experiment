# Prompt Template: Blind Benchmark

## Purpose
Run one existing benchmark task.

Use this prompt only when the task file and checklist already exist.
Do not redesign the task here.

## Inputs
- `SKILL_NAME`
- `DATASET_FILE`
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

## Required task-file format

`TASK_FILE` must contain these sections:

- `# Task`
- `## Deliverables`
- `## Inputs and Fixtures`
- `## Required Behavior`
- `## Required Commands`
- `## Judge Checklist`

The runner must:

- copy only the sections before `## Judge Checklist` into each trial as `TASK.md`
- use only `## Judge Checklist` for scoring

## Workflow

1. Read `TASK_FILE`, `ORIGINAL_SKILL`, and `VERIFIED_SKILL`.
2. Spawn one orchestrator subagent for the full run.
3. The orchestrator creates one temporary benchmark directory for the run under `/tmp/`.
4. Inside that directory, the orchestrator creates one trial directory per run.
   Each trial directory contains only:
   - `TASK.md`
   - `SKILL.md` only for skill-guided arms
   - any fixture files staged exactly as referenced by `TASK.md`
   - command outputs needed for scoring
5. Before spawning workers, the orchestrator validates that the task is trial-local:
   - worker-visible paths in `TASK.md` must stay inside the trial directory
   - required commands must not read from shared repo paths
   - required commands must not make different trials share an output path
   If any of these checks fail, stop and mark the run invalid.
6. The orchestrator stages each trial so it is self-contained:
   - every worker-visible path in `TASK.md` must resolve inside that trial directory
   - fixture files must be copied into that trial directory before the worker starts
   - no worker command may require reading from the repo root
7. The orchestrator spawns fresh worker trials.
   Trial count:
   - `2 * NUM_TRIALS` without no-skill
   - `3 * NUM_TRIALS` with no-skill
8. Each worker must run with its cwd set to its own trial directory.
9. The orchestrator must pass the absolute trial directory path to each worker in plain text.
10. Workers write the required output files only inside their own trial directory and run exactly the commands required by `TASK.md`.
11. The orchestrator waits for every trial to finish.
12. The orchestrator scores every trial using only the checklist in `TASK_FILE`.
13. After scoring all trials, the orchestrator extracts isolated failure samples from the trial artifacts.
14. The orchestrator writes those samples into `DATASET_FILE`.
15. The orchestrator unblinds the mapping and reports the outcome in its final message.
16. After extraction, the orchestrator deletes the temporary benchmark directory.

## Failure extraction

Write a small set of isolated failure samples into `DATASET_FILE`.

Use only these buckets:

- incorrect claim
- missing rule
- ambiguous wording
- conflicting guidance
- missing example
- low-signal noise

Only keep a sample when it is supported by a real trial artifact and is useful for refinement.
Do not copy whole trial logs into the dataset.

If `DATASET_FILE` already has `failure_samples`, preserve it.
If it does not, create:

```json
"failure_samples": []
```

Each new sample must be a small object like:

```json
{
  "source_type": "benchmark",
  "source_task": "blind_trials/{SKILL_NAME}/task_01_....txt",
  "bucket": "missing rule",
  "summary": "one-sentence failure description",
  "evidence": "one short code snippet or runtime observation",
  "check": "failed checklist item",
  "next_action": "new claim"
}
```

Allowed `next_action` values:

- `new claim`
- `stronger test`
- `skill edit`
- `benchmark rewrite`
- `no action`

Keep only isolated samples.
Do not store benchmark scores, full trial summaries, or complete command logs in the dataset.

## Worker instructions

Skill-guided worker:

```text
Your cwd is the trial directory.
The orchestrator will also tell you the absolute trial directory path.
Read ./SKILL.md and ./TASK.md from that directory.
Use only files staged inside that directory.
Write the required output files only inside that directory.
Run exactly the commands required by TASK.md from that directory.
If a command fails, fix the code and retry within that same directory.
After the trial is finished, return exactly ANNOUNCE_SKIP.
```

No-skill worker:

```text
Your cwd is the trial directory.
The orchestrator will also tell you the absolute trial directory path.
Read ./TASK.md from that directory.
Use only files staged inside that directory.
Write the required output files only inside that directory.
Run exactly the commands required by TASK.md from that directory.
If a command fails, fix the code and retry within that same directory.
After the trial is finished, return exactly ANNOUNCE_SKIP.
```

## Invalid-run rules

Mark the run invalid and stop if:
- the orchestrator cannot be spawned
- fresh independent worker trials cannot be created
- any trial output was authored by the orchestrator
- any arm uses simulated or hand-written substitute outputs instead of real worker trials
- any worker starts outside its own trial directory
- any worker reads required inputs from outside its own trial directory
- any worker writes benchmark outputs into a shared path outside its own trial directory
- any fixture path referenced by `TASK.md` is missing from the staged trial directory
- any two trials share an output path
- the runner reuses a session label that must be unique
- the task file still points workers at repo-root or stale fixture paths

Invalid runs report a short failure summary, not benchmark scores.

## Hard rules

- one orchestrator subagent per benchmark run
- use an existing task file
- do not redesign the task here
- one fresh worker subagent per trial
- workers may run in batches
- each trial must be self-contained
- each worker must run in its own trial directory
- each trial must have unique output paths
- each session label must be unique if labels are used
- no group labels in worker-visible context
- no hidden mapping in trial directories
- do not let the orchestrator author trial solutions
- do not summarize before all trials reach a terminal state
- do not create a benchmark result file
- do not keep benchmark trial directories after extraction unless the user explicitly asks

## Required artifacts

Keep these artifacts only until extraction is complete:

- one temporary benchmark directory under `/tmp/`
- one trial directory per worker
- every worker-authored output file
- the exact `TASK.md` each worker saw
- `SKILL.md` for skill-guided arms
- every staged fixture file
- command outputs needed for scoring

Do not create a benchmark result file.
After extraction, delete the temporary benchmark directory.
The final message is only a short summary of the run and the samples written to the dataset.

## Interpretation

- verified > original and no-skill: verified skill adds value
- verified > original but not no-skill: weak skill signal
- all arms similar and strong: task may be too easy or too specified
- all arms fail the same way: likely task or model-default issue first

## Reusability
Replace `{SKILL_NAME}`, `{DATASET_FILE}`, `{ORIGINAL_SKILL}`, `{VERIFIED_SKILL}`, `{TASK_FILE}`, `{NUM_TRIALS}`, `{INCLUDE_NO_SKILL}`, and `{ORCHESTRATOR_TIMEOUT_MINUTES}`.
