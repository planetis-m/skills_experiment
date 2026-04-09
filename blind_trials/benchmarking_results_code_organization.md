# Benchmark Results: nim-code-organization

## Task

Task file: [blind_trials/task_code_organization.txt](/home/ageralis/skills_experiment/blind_trials/task_code_organization.txt).

It asks the model to implement one small ordered-writer module with:

- one out-of-order completion source
- one ordered flush requirement
- one small public API
- helper placement left mostly open
- code-organization checks on state flow, exports, and dead imports

Deterministic parts:

- fixed public API
- fixed fake completion order
- fixed smoke assertions
- fixed compile/run command

## Judge Checklist

- compiles and runs with `nim c -r --mm:orc subject_solution.nim`
- runtime prints `SMOKE: PASS`
- `writtenIds` preserves original input order even when completion order is out of order
- `flushCalls` counts only productive flushes
- the exported surface contains the required public symbols and no obvious extra exported internals
- the implementation uses explicit orchestration state rather than hiding shared mutable flow inside nested helper captures
- helper procs, if present, are top-level rather than nested inside `runWriter`
- no nested proc captures mutable outer locals in the orchestration flow
- no unused imports are left in the file

## Current State

No benchmark results are recorded in this file yet.

The task was locally validated on 2026-04-09 with a temporary reference implementation that compiled and printed `SMOKE: PASS` under `nim c -r --mm:orc`.

## Default Benchmark Run

- arms: `original`, `verified`, `no-skill`
- `NUM_TRIALS = 3`
- `ORCHESTRATOR_TIMEOUT_MINUTES = 27`
- every trial must be produced by a fresh independent worker
- if independent workers are unavailable, the benchmark run is invalid and must stop

## Benchmark Audit

- Intended discriminator: whether the skill steers agents toward explicit orchestration state, top-level helpers, and narrow exports instead of nested capture-heavy flow.
- Main ceiling-risk assessment: medium. A strong generic model may still choose a monolithic but correct implementation, so the code-inspection rubric matters.
- Current failure interpretation: if all arms converge on the same runtime-correct structure, revisit the rubric before changing the skill.
