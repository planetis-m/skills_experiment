# Prompt Template: Blind Benchmark

## Purpose
Compare the original and verified skill on the same task using OpenClaw subagents in a way that is blind, fair, and easy to run.

## Inputs
- `ORIGINAL_SKILL`: path to `original_skills/{SKILL_NAME}/SKILL.md`
- `VERIFIED_SKILL`: path to `skills/{SKILL_NAME}/SKILL.md`
- `TASK_SPEC`: task prompt with exact requirements
- `NUM_TRIALS`: trials per skill, default `3`
- `INCLUDE_NO_SKILL`: whether to add a control arm with no skill file, default `true`

## Workflow

### 1. Use one orchestrator

The main agent should spawn exactly one orchestrator subagent for the whole benchmark run.

The orchestrator is responsible for:
- preparing trial directories
- keeping the hidden mapping
- spawning worker trials
- waiting for all trial outcomes
- scoring every trial
- unblinding after scoring
- extracting failure modes
- deleting temporary benchmark artifacts
- returning one final summary to the main agent

Do not let the main agent spawn all trial workers directly.

### 2. Fix one task and one rubric

Write one canonical task file from `{TASK_SPEC}`.

The task and rubric must be:
- identical for every trial
- binary per item: pass or fail
- directly checkable from compile output, runtime output, or code inspection
- based on one implementation convention only
- limited to checks the orchestrator can actually perform

For design-oriented skills, make the task large enough for the orchestrator to inspect the anti-patterns the skill is supposed to prevent.

### 3. Create opaque trial IDs

Do not use labels such as `A1`, `A2`, `B1`, or `B2` inside worker-visible context.

Instead:
1. Create opaque IDs such as `run_01`, `run_02`, ..., `run_0N`
2. Randomly assign each run to one of the two skills
3. Keep that mapping private until scoring is complete

The hidden mapping must not appear in:
- worker prompts
- trial directories
- workspace bootstrap files

### 4. Prepare one trial directory per run

For each run, create one directory that contains only:
- `SKILL.md`
- `TASK.md`
- the destination path for `subject_solution.nim`

Do not place these in the trial directory:
- the other skill
- any hidden mapping file
- any benchmark summary
- any note saying original, verified, group A, or group B

### 5. Spawn one worker per trial

The orchestrator should spawn:
- `2 * NUM_TRIALS` fresh worker subagents when `INCLUDE_NO_SKILL` is `false`
- `3 * NUM_TRIALS` fresh worker subagents when `INCLUDE_NO_SKILL` is `true`

Each worker gets:
- one trial directory
- one `SKILL.md`, unless this is a `NO SKILL` control run
- one `TASK.md`
- one output path: `subject_solution.nim`
- one timeout budget

Use the same model, tool policy, sandbox mode, and prompt style for every worker run.

Use this instruction shape for every worker:

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

For `NO SKILL` control runs:
- omit `SKILL.md`
- keep the rest of the worker setup identical
- use this worker instruction shape instead:

```text
Read ./TASK.md.
Write the required solution to ./subject_solution.nim.
Run exactly the compile and/or run commands required by TASK.md.
If a command fails, fix the code and retry within this trial directory.
Do not discuss benchmarking, groups, other trials, or alternative skills.
After the trial is finished, return exactly ANNOUNCE_SKIP.
```

### 6. Wait for all trial outcomes

OpenClaw subagent spawns are non-blocking.

Treat each trial as pending until it reaches one terminal outcome:
- success
- error
- timeout

The orchestrator must not return the benchmark result while any trial is still pending.

If a worker times out or fails, keep that trial and score it as a failed generation. Do not silently replace it.

### 7. Score inside the orchestrator

After every trial is terminal, the orchestrator scores all trials itself.

For each trial:
1. Check `COMPILE` first
2. Score every rubric item exactly as written
3. Write `verdict.json`

If the task is style-sensitive, the orchestrator may score explicit anti-pattern checks by reading the generated code.

### 8. Unblind only after scoring

After every trial has a verdict:
1. Aggregate results by hidden bucket
2. Only then reveal which bucket used which skill or control
3. Compare:
   - verified skill vs original skill
   - verified skill vs no skill, when `INCLUDE_NO_SKILL` is `true`
   - original skill vs no skill, when `INCLUDE_NO_SKILL` is `true`
4. Extract the concrete failure modes needed for refinement
   Use only these buckets:
   - incorrect claim
   - missing rule
   - ambiguous wording
   - conflicting guidance
   - missing example
   - low-signal noise
   For each bucketed failure, include one short evidence line from the scored outcome.
5. Delete the temporary run directories and verdicts
6. Return one synthesized summary to the main agent

### Interpreting the control arm

When `INCLUDE_NO_SKILL` is `true`, use these rules:
- If verified beats original and no-skill, the skill is adding real value.
- If verified beats original but not no-skill, the verified skill may not be adding meaningful value.
- If all three arms perform similarly well, the task may be too easy or too specified.
- If all three arms fail in the same way, treat that as task wording, rubric, or model-default behavior first, not automatically as a skill problem.
- If no-skill performs much worse, the benchmark is likely measuring useful skill guidance rather than generic competence alone.

## OpenClaw notes

- Worker runs that only write files should finish with the exact token `ANNOUNCE_SKIP`
- If a late child completion arrives after the parent already finished, reply with `NO_REPLY` as cleanup only
- Do not store the hidden mapping in workspace bootstrap files such as `AGENTS.md`, `TOOLS.md`, `SOUL.md`, `USER.md`, `IDENTITY.md`, or `MEMORY.md`

## Hard rules

- one orchestrator per benchmark run
- one fresh worker subagent per trial
- one task, one rubric, one convention
- no group labels in worker prompts
- no hidden mapping in trial directories
- no final summary while any trial is still pending
- delete temporary run artifacts after extracting findings
- include a `NO SKILL` control arm by default unless there is a clear reason not to

## Leak rule

If a worker says anything like:
- "Both A2 and A3 have the same skill"
- "This looks like the refined skill"
- "I already used this skill in another run"

then:
1. discard that run
2. remove the leaked context
3. rerun it with a fresh worker subagent

## Reusability
Replace `{SKILL_NAME}`, `{ORIGINAL_SKILL}`, `{VERIFIED_SKILL}`, `{TASK_SPEC}`, `{NUM_TRIALS}`, and `{INCLUDE_NO_SKILL}` with the target values.
