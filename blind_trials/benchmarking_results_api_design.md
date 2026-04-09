# Benchmark Results: nim-api-design

## Task

Task file: [blind_trials/task_api_design.txt](/home/ageralis/skills_experiment/blind_trials/task_api_design.txt).

It asks the model to implement one small library module with:

- one primary public catalog type
- one coherent constructor surface
- one named metadata object
- `distinct` for domain safety
- one primary metadata read entrypoint
- one narrow tag-mutation path
- optional convenience readers

Deterministic parts:

- fixed `PackageId` and `PackageMeta`
- fixed runtime behavior
- fixed smoke assertions
- fixed compile/run command
- fixed API surface map comment
- a small code-shape rubric

## Judge Checklist

- compiles and runs with `nim c -r --mm:orc subject_solution.nim`
- runtime prints `SMOKE: PASS`
- `PackageId` is a `distinct string` with borrowed `==` and `$`
- exactly one primary public catalog type exists
- the public API exposes one empty constructor and one seed constructor
- there is no second public catalog representation
- public semantic data uses named objects, not status tuples
- the read surface is coherent: one primary metadata read entrypoint, plus only optional convenience readers
- the mutation surface is narrow: one clear tag-mutation path and no scalar `var` accessors
- the API surface map is present and matches the exported API
- missing data is not reported via silent defaults
- missing-package reads raise a specific catchable exception
- borrowed accessors, if used, do not rely on temp locals that create escaping-borrow issues
- public names are descriptive rather than generic

## Current State

No benchmark results are recorded in this file yet.

The current task was revalidated locally on 2026-04-09 with a temporary
reference implementation that compiled and printed `SMOKE: PASS` under
`nim c -r --mm:orc`.

## Default Benchmark Run

- arms: `original`, `verified`, `no-skill`
- `NUM_TRIALS = 3`
- `ORCHESTRATOR_TIMEOUT_MINUTES = 27`
- every trial must be produced by a fresh independent worker
- if independent workers are unavailable, the benchmark run is invalid and must stop

## Benchmark Audit

- Intended discriminator: whether the skill steers agents toward a narrower, more coherent public API instead of merely producing runtime-correct catalog behavior.
- Main ceiling-risk assessment: medium to high. The task is strongly specified, so a strong model may still produce good API shape without much help from the skill.
- Current failure interpretation: if all arms converge, treat that as a benchmark-signal problem first rather than a reason to edit the skill.
