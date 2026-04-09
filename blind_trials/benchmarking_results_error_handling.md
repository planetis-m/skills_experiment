# Benchmark Results: nim-error-handling

## Task

Task file: [blind_trials/task_error_handling.txt](/home/ageralis/skills_experiment/blind_trials/task_error_handling.txt).

It asks the model to implement one small batch pipeline with:

- one bool-return parse helper
- one explicit retry rule
- one explicit final-failure classifier
- ordered per-item outcomes
- one fatal audit-write boundary
- one app-level cleanup boundary

Deterministic parts:

- fixed public API
- fixed helper behavior
- fixed smoke assertions
- fixed exit-code behavior

## Judge Checklist

- compiles and runs with `nim c -r --mm:orc subject_solution.nim`
- runtime prints `SMOKE: PASS`
- `parseRetryLimit` is a bool-return parse helper
- `shouldRetry` matches the required retry behavior
- `classifyFinalFailure` matches the required classification behavior
- `runBatch` returns ordered per-item outcomes
- retryable `429` and transport timeout cases succeed on the second attempt
- parse failure is recorded as `ParseError`
- input failures are recorded as `InputError`
- audit-write failure escapes with added context and causes `runApp` to return `ExitFatalRuntime`
- `runApp` closes on non-fatal completion and aborts on fatal completion
- no ad-hoc intermediate result types were introduced
- no pointless `Positive` validation was added
- no repetitive local `try/except` wrappers were added around every raising call
- no bare `Exception` catch was used

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

- Intended discriminator: whether the skill changes boundary placement, retry shape, cleanup placement, and exception translation instead of only producing the required runtime results.
- Main ceiling-risk assessment: medium. The runtime behavior is specific, but the checklist still leaves room for real differences in error-boundary shape.
- Current failure interpretation: if all arms converge, review whether the task is over-specifying helper structure before changing the skill.
