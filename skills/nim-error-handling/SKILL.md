---
name: nim-error-handling
description: Design Nim exception boundaries, translation, cleanup, and parse-failure behavior.
---

# Preamble

Use this skill when deciding where exceptions should be raised, caught, translated, retried, or turned into structured output.
Larger examples live under `skills/nim-error-handling/references/`.

# Rules

## Boundaries

- Pick one failure style per layer. Internal step functions raise; orchestrator boundaries may return structured per-item outcomes.
- Catch only when you can recover, translate the error, or turn it into actionable output.
- Do not wrap each raising call in its own local `try/except` when there is no local recovery, translation, or cleanup boundary.
- Use structured result objects only at orchestrator boundaries where each item needs its own success or failure record.
- Do not pass ad-hoc `ok/kind/message` step objects through straight-line internal flows.

## Exceptions

- Use `CatchableError` as the recoverable catch-all. Do not catch bare `Exception`.
- Use specific exception types such as `IOError`, `ValueError`, and `OSError` when callers should distinguish them.
- Translate low-level errors at module boundaries with `getCurrentExceptionMsg()` so the caller gets the original reason plus local context.
- Use separate `except` branches only when different exception types need different handling. Otherwise share one branch.
- Use `except X as e` only when you need fields from the exception object itself.
- Do not add custom exception types unless callers handle them differently from existing ones.

## Helpers And APIs

- Bool-return parse helpers should catch `CatchableError` once and return `false`.
- For range-typed parameters such as `Positive`, trust the type for the basic domain and raise only for additional semantic bounds such as `pageNo > pages.len`.
- Give public boundary procs and result types descriptive names. Avoid generic names such as `Result`, `Data`, or `handleError`.
- Raise clear, bounded messages that identify the failed operation and preserve the underlying reason.
- `{.noinline.}` on heavy error-message builders is an optimization, not a default rule. Use it only for hot wrappers that build large messages repeatedly.

## Cleanup And Retry

- Use `try/finally` for cleanup. `except` is for error handling, not resource release.
- Distinguish retriable failures from final failures before deciding whether to continue or raise.
- On final retry failure, raise a descriptive exception. Do not silently return a partial failure.

# Workflow

1. Classify the code site.
   Internal step raises; bool parse helper catches once; module boundary translates; orchestrator boundary records per-item output; cleanup path uses `finally`; retry loop classifies retriable vs final failure.
2. Keep the success path straight-line.
   If a proc just chains work such as `load -> build -> publish`, let failures propagate instead of repackaging them locally.
3. Translate only at real boundaries.
   Re-raise when you can add contract or subsystem context, for example `audit write failed for foo.log: ...`.
4. Shape public outputs at the orchestrator boundary.
   Record success and failure per item there instead of threading intermediate step results through internal procs.
5. Verify the code shape with the repo tests.
   Run `nim c -r --mm:orc tests/nim-error-handling_verification/test_c23_positive_range_guard.nim` for range-typed behavior and run the rest of `tests/nim-error-handling_verification/test_*.nim` for the established exception patterns.

Inline example:

```nim
proc writeAuditLine(auditPath: string; line: string) =
  try:
    fakeAuditWrite(auditPath, line)
  except OSError:
    raise newException(IOError, "audit write failed for " & auditPath & ": " &
        getCurrentExceptionMsg())
```

# Common Mistakes

| Mistake | Why it is wrong |
|---------|-----------------|
| Catching in every layer | Hides the real boundary and makes failures harder to reason about. |
| Wrapping each raising call in its own `try/except` | Adds noise without creating a new recovery or translation boundary. |
| Catching bare `Exception` | Also catches `Defect`, which is not recoverable application flow. |
| Passing `ok/kind/message` objects between steps | Reimplements exception propagation with more boilerplate and less information. |
| Checking `Positive` or other range types with manual `<= 0` guards | Repeats a constraint the type already enforces and pushes the code toward Python-style validation. |
| Naming a public boundary type `Result` or a proc `handleError` | Hides purpose at the API boundary where clarity matters most. |
| Swallowing an exception | Loses the failure without recovery or reporting. |
| Using `try/except` for cleanup | Cleanup belongs in `finally`, whether an exception happened or not. |
| Adding custom exception types with no distinct handling | Adds type noise without changing behavior. |
| Returning quietly after retries are exhausted | Hides final failure from the caller. |

# References

- `references/batch_preview_boundary.md`: End-to-end batch preview example with parse helper, translation boundary, and per-item orchestrator results.
- `references/retry_classification.md`: Retry loop example that separates retriable failures from final failures.

# Changelog

- 2026-04-08: Added verified range-typed parameter guidance and recorded the missing benchmark-only claims.
- 2026-04-08: Restructured the skill into the repo's Phase 4 layout and moved larger examples into `references/`.
