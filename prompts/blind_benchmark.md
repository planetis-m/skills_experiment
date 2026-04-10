# Prompt Template: Blind Benchmark

## Purpose

Run one existing benchmark task.

Use this prompt only when the task file and judge checklist already exist.
Do not redesign the task here.

## Repo-local skill paths

In this repo, skill paths are repo-local only:

- `ORIGINAL_SKILL = original_skills/{SKILL_NAME}/SKILL.md`
- `VERIFIED_SKILL = skills/{SKILL_NAME}/SKILL.md`

Do not resolve skills from installed locations, home-directory skill stores, or paths outside this repo.

## Inputs

- `SKILL_NAME`
- `DATASET_FILE`
- `ORIGINAL_SKILL`
- `VERIFIED_SKILL`
- `TASK_FILE`
- `NUM_TRIALS` default `3`
- `ORCHESTRATOR_TIMEOUT_MINUTES` default `27`

## Default run shape

Use this run shape unless the user explicitly asks for a different one:

- one benchmark run
- one orchestrator subagent
- three arms: `original`, `verified`, `no-skill`
- `NUM_TRIALS = 3`
- for each trial index from `1` to `NUM_TRIALS`, spawn exactly three workers:
  - one `original`
  - one `verified`
  - one `no-skill`
- total workers = `3 * NUM_TRIALS`
- workers may run in batches
- orchestrator timeout `27` minutes

If a required repo-local skill file is missing, the run is invalid and must stop.
Do not silently drop an arm.
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
2. Confirm that `ORIGINAL_SKILL` and `VERIFIED_SKILL` are the repo-local paths for this skill.
3. Before starting a new run, delete stale temporary benchmark directories for this skill under `/tmp/benchmark_{SKILL_NAME}_*`.
4. Create one new run directory under `/tmp/benchmark_{SKILL_NAME}_*`.
5. Inside that run directory, create one self-contained trial directory per worker.
6. Stage each trial directory before spawning workers:
   - write `TASK.md`
   - write `SKILL.md` for `original` and `verified`
   - do not write `SKILL.md` for `no-skill`
   - copy every fixture file referenced by `TASK.md`
   - make sure every worker-visible path in `TASK.md` resolves inside that trial directory
   - make sure required commands do not read from shared repo paths
   - make sure different trials do not share an output path
7. If any trial-local check fails, stop and mark the run invalid.
8. Spawn one fresh worker subagent for every staged trial directory.
9. Run each worker with its cwd set to its own trial directory.
10. Pass the absolute trial directory path to each worker in plain text.
11. Wait for every worker trial to finish.
12. Score every trial only from the files in the current run directory, using only `## Judge Checklist`.
13. Extract isolated failure samples into `DATASET_FILE`.
14. Unblind the arm mapping and report the outcome.

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

## Failure extraction

Write isolated failure samples into `DATASET_FILE`.

Use only these buckets:

- incorrect claim
- missing rule
- ambiguous wording
- conflicting guidance
- missing example
- low-signal noise

Only keep a sample when it is supported by a real trial artifact and useful for refinement.
Do not copy whole trial logs into the dataset.
Do not store benchmark scores or full trial summaries in the dataset.

If `DATASET_FILE` already has `failure_samples`, preserve it.
If it does not, create:

```json
"failure_samples": []
```

Each sample should look like:

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
- the task file still points workers at repo-root or stale fixture paths
- `ORIGINAL_SKILL` or `VERIFIED_SKILL` was resolved from outside this repo
- a required arm was dropped
- the number of spawned workers does not equal `3 * NUM_TRIALS`
- any trial index is missing any of the three arms

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
- do not set session labels
- no group labels in worker-visible context
- no hidden mapping in trial directories
- do not let the orchestrator author trial solutions
- do not summarize before all trials reach a terminal state
- do not create a benchmark result file
- delete stale temporary benchmark directories only before starting a new run

## Required artifacts

The current run directory must contain:

- one temporary benchmark directory under `/tmp/`
- one trial directory per worker
- every worker-authored output file
- the exact `TASK.md` each worker saw
- `SKILL.md` for skill-guided arms
- every staged fixture file
- command outputs needed for scoring

Do not create a benchmark result file.
Report only a short run summary and the samples written to the dataset.

## Interpretation

- verified > original and no-skill: verified skill adds value
- verified > original but not no-skill: weak skill signal
- all arms similar and strong: task may be too easy or too specified
- all arms fail the same way: likely task or model-default issue first

## Reusability

Replace `{SKILL_NAME}`, `{DATASET_FILE}`, `{ORIGINAL_SKILL}`, `{VERIFIED_SKILL}`, `{TASK_FILE}`, `{NUM_TRIALS}`, and `{ORCHESTRATOR_TIMEOUT_MINUTES}`.
