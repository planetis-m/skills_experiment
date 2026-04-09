# Benchmark Results: nim-style-guide

## Task

Task file: [blind_trials/task_style_guide.txt](/home/ageralis/skills_experiment/blind_trials/task_style_guide.txt).

It asks the model to implement one small rule parser module with:

- a parser state object plus `open`, `next`, `close`, and `renderSummary`
- accepted, skipped, rejected, duplicate, and eof paths
- repeated state updates across multiple exported procs
- one natural place for a tiny validation helper
- one natural place where the main parser proc should keep a clearer normal path
- direct code-shape checks for style-guide choices

Deterministic parts:

- fixed public API
- fixed runtime behavior
- fixed smoke assertions
- fixed compile/run command
- fixed code-inspection checklist

## Judge Checklist

- compiles and runs with `nim c -r --mm:orc subject_solution.nim`
- runtime prints `SMOKE: PASS`
- `open`, `next`, `close`, and `renderSummary` match the required behavior
- accepted rules preserve original accepted order and the counters are correct
- the exported surface contains the required public symbols and no obvious extra exported internals
- no `continue` statement appears in the file
- no `type` block appears inside a proc
- helpers with their own control flow, if present, are `proc` or `func`, not `template`
- helper procs, if present, are top-level rather than nested inside exported procs
- no obvious one-argument-per-line call blocks are used where a compact wrapped call would fit naturally
- object construction does not restate defaulted fields when the defaults are intended to remain unchanged
- no unused imports are left in the file

## Current State

The previous replacement task was benchmarked on 2026-04-09 and still hit the ceiling: all three arms scored `12/12`.

Observed convergence from the preserved trial artifacts:

- most runs kept almost all logic inline
- the only meaningful variation was tiny helper extraction
- the main difference between arms was usually `func` versus `proc` for a pure helper
- the previous task did not create enough structural surface for the checklist to matter

The current task replaces that weaker version in place.

The current replacement task was locally validated on 2026-04-09 with a temporary reference implementation that compiled and printed `SMOKE: PASS` under `nim c -r --mm:orc`.

## Default Benchmark Run

- arms: `original`, `verified`, `no-skill`
- `NUM_TRIALS = 3`
- `ORCHESTRATOR_TIMEOUT_MINUTES = 27`
- every trial must be produced by a fresh independent worker
- if independent workers are unavailable, the benchmark run is invalid and must stop

## Benchmark Audit

- Intended discriminator: whether the skill steers agents toward a clearer parser-module shape, including concise tiny helpers, straighter exported parser procs, and a narrow export surface.
- Main ceiling-risk assessment: medium. The task is still small enough to repeat, but it now includes parser state, repeated exported operations, and incremental progression, which should create more real variation than the previous tasks.
- Current failure interpretation: if all arms still converge on this task, the model is likely following this style profile by default on medium-sized module tasks, and the next benchmark should increase module surface again rather than add smaller checklist rules.
