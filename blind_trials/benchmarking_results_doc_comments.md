# Benchmark Results: nim-doc-comments

## Task

Task file: [blind_trials/task_doc_comments.txt](/home/ageralis/skills_experiment/blind_trials/task_doc_comments.txt).

It asks the model to implement and document one small module with:

- module docs before imports
- declaration-attached docs for exported `const` and `type` symbols
- declaration-line docs for enum values and object fields
- one multi-line continuation doc on a type declaration
- proc docs after the signature
- rendered-output verification through `nim doc`

Deterministic parts:

- fixed public API
- fixed runtime behavior
- fixed required doc phrases
- fixed compile/run and `nim doc` commands
- fixed source-placement requirements

## Judge Checklist

- compiles and runs with `nim c -r --mm:orc subject_solution.nim`
- runtime prints `SMOKE: PASS`
- `nim doc --outdir:htmldocs subject_solution.nim` succeeds
- module docs appear before imports
- `DefaultDepth` uses a declaration-attached inline trailing `##` comment
- `ParseMode` and `ParseConfig` type docs are attached to their declaration lines
- `CountReport` uses declaration-attached docs with an aligned continuation `##` line
- enum value docs and object field docs are attached to their declaration lines
- `countTokens` docs appear immediately after the proc signature
- rendered docs contain all required phrases
- the private helper does not appear in rendered docs
- no `runnableExamples:` block was added

## Current State

The current task was locally validated on 2026-04-09 with a temporary reference implementation that:

- compiled and ran under `nim c -r --mm:orc`
- printed `SMOKE: PASS`
- rendered successfully with `nim doc --outdir:htmldocs`
- satisfied the required source-placement checks in the reference source

No blind benchmark results are recorded for this task version yet.

## Default Benchmark Run

- arms: `original`, `verified`, `no-skill`
- `NUM_TRIALS = 3`
- `ORCHESTRATOR_TIMEOUT_MINUTES = 27`
- every trial must be produced by a fresh independent worker
- if independent workers are unavailable, the benchmark run is invalid and must stop

## Benchmark Audit

- Intended discriminator: whether the skill helps agents place docs correctly in source, especially on type declarations inside `type` blocks and on declaration-attached continuation docs.
- Main ceiling-risk assessment: lower than the previous version because passing now requires both correct rendered output and correct source placement.
- Current failure interpretation: if no-skill still matches the skill-guided arms, the task is still too easy and should be tightened again before changing the skill.
