# Benchmark Results: nim-style-guide

## Task

Task file: [blind_trials/task_style_guide.txt](/home/ageralis/skills_experiment/blind_trials/task_style_guide.txt).

It asks the model to implement one small parsing module with:

- one fixed public API
- one style-relevant defaulted object type
- one branch where `pmLenient` tempts use of `continue`
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
- strict mode raises on empty trimmed items
- lenient mode skips empty trimmed items and counts them in `skipped`
- accepted items preserve original order after trimming
- the exported surface contains the required public symbols and no obvious extra exported internals
- no `continue` statement appears in the file
- no `type` block appears inside a proc
- helpers with their own control flow, if present, are `proc` or `func`, not `template`
- no obvious one-argument-per-line call blocks are used where a compact wrapped call would fit naturally
- the code uses object construction without restating defaulted fields when the defaults are intended to remain unchanged
- no unused imports are left in the file

## Current State

No benchmark results are recorded in this file yet.

The task was locally validated on 2026-04-09 with a temporary reference implementation that compiled and printed `SMOKE: PASS` under `nim c -r --mm:orc`.

## Benchmark Audit

- Intended discriminator: whether the skill steers agents toward the guide's preferred code shape instead of merely producing runtime-correct code.
- Main ceiling-risk assessment: medium. A strong no-skill run may still produce readable code, but the checklist should expose recurring defaults such as `continue`, nested declarations, control-flow templates, and noisy constructors.
- Current failure interpretation: if all arms converge, the task may still be too easy or the checklist may be scoring style details that strong models already satisfy without guidance.
