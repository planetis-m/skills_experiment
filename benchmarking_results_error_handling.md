# Benchmark Results: nim-error-handling

## Canonical Task

The canonical benchmark task is [blind_trials/task_error_handling.txt](/home/ageralis/skills_experiment/blind_trials/task_error_handling.txt).

It asks the model to implement one small batch pipeline with:

- one bool-return parse helper
- one explicit retry rule
- one explicit final-failure classifier
- ordered per-item outcomes
- one fatal audit-write boundary
- one app-level cleanup boundary

The task is intentionally deterministic:

- fixed public API
- fixed helper behavior
- fixed smoke assertions
- fixed exit-code behavior

At the same time, it does not prescribe the full internal proc breakdown, so the skill still has room to affect boundary placement and retry design.

## Why This Replaced The Old Task

The earlier error-handling task specified too much of the solution directly:

- exact internal proc roles
- explicit anti-pattern list in the task body
- almost complete boundary guidance

That made it too easy for different skills to converge on the same implementation.

The current task keeps the observable contract fixed, but moves most design judgment into the rubric instead of the prompt body.

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

## Status

No benchmark results are recorded in this file yet.

This task definition is the current canonical benchmark for `nim-error-handling`.
