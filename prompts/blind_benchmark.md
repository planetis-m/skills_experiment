# Prompt Template: Blind Benchmark

## Purpose
Compare the original and verified skill on the same task using subagents, while keeping generation blind and scoring fair.

## Inputs
- `ORIGINAL_SKILL`: path to `original_skills/{SKILL_NAME}/SKILL.md`
- `VERIFIED_SKILL`: path to `skills/{SKILL_NAME}/SKILL.md`
- `TASK_SPEC`: task prompt with exact requirements
- `NUM_TRIALS`: trials per skill, default `3`

## Core idea

Use the documented OpenClaw nested-subagent pattern:

- **main**: starts one benchmark run
- **orchestrator subagent**: prepares trials, keeps the hidden mapping, launches workers, waits for all worker outcomes, scores all trials, and returns one synthesized result to main
- **worker subagents**: each handles exactly one trial

The generator subagent must never see:
- original vs verified labels
- A-group / B-group labels
- any other trial
- any statement like "A2 and A3 use the same skill"

If that happens, the run is not blind.

## OpenClaw rules

OpenClaw injects workspace context into agent runs, and `sessions_spawn` is non-blocking. Use the harness in the way the docs expect:

- enable nested subagents with `maxSpawnDepth: 2`
- main spawns one orchestrator subagent, not all workers directly
- the orchestrator spawns one fresh worker subagent per trial
- each worker spawn should use a timeout
- give each trial an opaque ID such as `run_01`
- give each trial its own directory
- keep hidden mapping out of the trial directories
- do not mention other trials in worker prompts

Do not put the hidden mapping in workspace bootstrap files such as `AGENTS.md`, `SOUL.md`, `TOOLS.md`, `USER.md`, `IDENTITY.md`, or `MEMORY.md`.

Benchmark run artifacts are temporary:
- do not commit prior run directories
- do not commit `verdict.json`
- do not commit benchmark result summaries
- keep only the canonical task files and any reusable helper programs in the repo

Worker completion handling:
- workers that only write files should finish with the exact token `ANNOUNCE_SKIP`
- the orchestrator reads the worker outputs from files and synthesizes the benchmark result
- the orchestrator must not return a final benchmark summary while any worker is still pending
- only use `NO_REPLY` as cleanup for an unexpected late child completion after the parent already finished

## Step 1: Fix one task and one rubric

Write one canonical task file from `{TASK_SPEC}`.

The task and rubric must be:
- identical for every trial
- binary per item: pass or fail
- directly checkable from compile output, runtime output, or code inspection
- consistent with one chosen implementation convention
- limited to checks the judge can actually perform

For design-oriented skills, make the task large enough for the judge to inspect the anti-patterns the skill is supposed to prevent.

## Step 2: Create opaque trial IDs

Do not use `A1`, `A2`, `B1`, `B2` inside generator or judge prompts.

Instead:
1. Create opaque IDs such as `run_01`, `run_02`, ..., `run_0N`
2. Randomly assign each run to one of the two skills
3. Keep that mapping private until scoring is complete

The mapping may exist only in controller-only notes or files outside the trial directories.

## Step 3: Prepare one trial directory per run

For each run, create a directory that contains only:
- `SKILL.md`
- `TASK.md`
- the destination path for `subject_solution.nim`

Do not place these in the trial directory:
- the other skill
- any mapping file
- any verdict file from another run
- any benchmark summary
- any note saying original, verified, A-group, or B-group

## Step 4: Spawn worker subagents from the orchestrator

The orchestrator spawns `2 * NUM_TRIALS` fresh worker subagents.

Each worker subagent gets:
- one trial directory
- the `SKILL.md` in that directory
- the `TASK.md` in that directory
- one output path: `subject_solution.nim`
- one timeout budget

Use the same model, tool policy, sandbox mode, and prompt style for every worker run.

Use this instruction shape for every worker subagent:

```text
Read ./SKILL.md and ./TASK.md.
Write the required solution to ./subject_solution.nim.
Run exactly the compile and/or run commands required by TASK.md.
If a command fails, fix the code and retry within this trial directory.
Do not discuss benchmarking, groups, other trials, or alternative skills.
After the trial is finished, return exactly ANNOUNCE_SKIP.
```

Do not tell the worker:
- that other runs share the same skill
- that it is part of group A or B
- that it is using the original or verified skill

The orchestrator should then wait for worker completion events and continue from the files written in each trial directory. It should not rely on main receiving worker completions directly.

Treat each worker trial as pending until it reaches one terminal outcome:
- success
- error
- timeout

Do not return the benchmark result while any trial is still pending.

## Step 5: Score inside the orchestrator

The orchestrator scores all trials itself after every trial is terminal.

For each trial, the orchestrator should read only:
- `TASK.md`
- `subject_solution.nim`
- that trial's compile/runtime output if needed

The orchestrator should score every trial with the same rubric:
1. Check `COMPILE` first
2. Score every rubric item exactly as written
3. Write `verdict.json`

If the task is style-sensitive, the orchestrator may score explicit anti-pattern checks by reading the generated code.

## Step 6: Aggregate, then unblind

After every trial has a verdict:
1. The orchestrator aggregates results by hidden bucket
2. Only then does the orchestrator reveal which bucket used which skill
3. The orchestrator extracts the concrete failure modes needed for refinement
4. The orchestrator deletes the temporary run directories and verdicts
5. The orchestrator returns one synthesized result to main

Only after this step may any private operator notes use labels such as original or verified.

## Step 7: Feed back

If the benchmark exposes real weaknesses:
1. Note the concrete failure modes
2. Add them to dataset gaps or stronger-test notes
3. Feed them back into Phase 1 as new or corrected claims
4. Do not rewrite the skill inside the benchmark step itself

## Hard rules

- main spawns one orchestrator subagent for the whole benchmark run
- one fresh worker subagent per trial
- one task, one rubric, one convention
- no group labels in worker prompts
- no hidden mapping in trial directories
- no cross-trial context in worker prompts
- no final benchmark summary while any worker trial is still pending
- workers should normally finish with `ANNOUNCE_SKIP`
- if a late child completion arrives after the parent already answered, respond with `NO_REPLY` as cleanup only
- delete run directories and verdicts after harvesting the findings

## Leak check

If a worker says anything like:
- "Both A2 and A3 have the same skill"
- "This looks like the refined skill"
- "I already used this skill in another run"

then:
1. discard that run
2. remove the leaked context
3. rerun it with a fresh worker subagent

## Reusability
Replace `{SKILL_NAME}`, `{ORIGINAL_SKILL}`, `{VERIFIED_SKILL}`, `{TASK_SPEC}`, and `{NUM_TRIALS}` with the target values.
