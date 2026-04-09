# Benchmark Results: nim-style-guide

## Task

Task file: [blind_trials/task_style_guide.txt](/home/ageralis/skills_experiment/blind_trials/task_style_guide.txt).

It asks the model to implement one small parsing pipeline with:

- one fixed public API
- two exported procs with different responsibilities
- two style-relevant defaulted object types
- multiple branches where `pmLenient` tempts `continue`, nested helpers, or control-flow templates
- multiple object-construction sites where default-field restatement is tempting
- helper placement and names left mostly open
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
- `classifyItem` matches the required strict and lenient behavior
- `parseItems` preserves accepted-item order and correct counters
- the exported surface contains the required public symbols and no obvious extra exported internals
- no `continue` statement appears in the file
- no `type` block appears inside a proc
- helpers with their own control flow, if present, are `proc` or `func`, not `template`
- helper procs, if present, are top-level rather than nested inside `parseItems`
- no obvious one-argument-per-line call blocks are used where a compact wrapped call would fit naturally
- object construction does not restate defaulted fields when the defaults are intended to remain unchanged
- no unused imports are left in the file

## Current State

No benchmark results are recorded in this file yet.

The previous style-guide task was too easy: all completed trials scored perfectly regardless of arm.

The current replacement task was locally validated on 2026-04-09 with a temporary reference implementation that compiled and printed `SMOKE: PASS` under `nim c -r --mm:orc`.

## Default Benchmark Run

- arms: `original`, `verified`, `no-skill`
- `NUM_TRIALS = 3`
- `ORCHESTRATOR_TIMEOUT_MINUTES = 27`
- every trial must be produced by a fresh independent worker
- if independent workers are unavailable, the benchmark run is invalid and must stop

## Benchmark Audit

- Intended discriminator: whether the skill steers agents toward the guide's preferred helper shape, loop structure, constructor use, and narrow export surface instead of merely producing runtime-correct code.
- Main ceiling-risk assessment: lower than the previous task, because there are now multiple helpers, multiple branch sites, and multiple constructor sites where style choices can diverge.
- Current failure interpretation: if all arms still converge, the model is likely satisfying this style profile by default and the benchmark should add even more structural surface rather than more tiny checklist rules.
