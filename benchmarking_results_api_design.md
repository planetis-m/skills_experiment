# Benchmark Results: nim-api-design

## Task

Task file: [blind_trials/task_api_design.txt](/home/ageralis/skills_experiment/blind_trials/task_api_design.txt).

It asks the model to implement one small library module with:

- one primary public representation
- one coherent constructor surface
- named semantic result/data types
- `distinct` for domain safety
- `lent` read accessors
- one `var` accessor only for an intentionally mutable reference-like field
- one shared missing-item error helper

Deterministic parts:

- fixed public types
- fixed runtime behavior
- fixed smoke assertions
- fixed compile/run command
- fixed API-role map comment
- a small code-shape rubric

## Judge Checklist

- compiles and runs with `nim c -r --mm:orc subject_solution.nim`
- runtime prints `SMOKE: PASS`
- `PackageId` is a `distinct string` with borrowed `==` and `$`
- the public API exposes one empty constructor and one conversion constructor
- there is no second public catalog representation
- public semantic data uses named objects, not status tuples
- the read surface includes a full-metadata accessor and scalar read access
- exactly one public mutable accessor exposes the stored tag sequence
- no scalar `var` accessor is exposed
- the API role map is present and matches the exported procs
- missing-package failures go through one shared private `{.noinline, noreturn.}` helper
- missing data is not reported via silent defaults
- accessor code does not use temp locals that would create escaping-borrow issues
- public names are descriptive rather than generic

## Current State

No benchmark results are recorded in this file yet.

The task was revalidated locally on 2026-04-09 with a
temporary reference implementation that compiled and printed `SMOKE: PASS`
under `nim c -r --mm:orc`.
