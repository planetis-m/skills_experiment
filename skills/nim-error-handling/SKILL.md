---
name: nim-error-handling
description: Design Nim exception boundaries, translation, cleanup, and parse-failure behavior.
---

# Preamble

Use this skill when deciding where exceptions should be raised, caught, translated, retried, or turned into structured output.
Larger examples live under `references/`.

# Rules

## Boundaries

- Internal step procs raise.
- Bool parse helpers catch once and return `false`.
- Orchestrator boundaries may return structured per-item outcomes.
- Catch only to recover, translate, or record failure.
- Do not wrap every raising call in its own local `try/except`.
- Do not pass `ok/kind/message` step objects through straight-line internal flows.

## Exceptions

- Use `CatchableError` as the recoverable catch-all. Do not catch bare `Exception`.
- Use specific exception types such as `IOError`, `ValueError`, and `OSError` when callers should distinguish them.
- Translate low-level errors at module boundaries by adding local context and preserving the original reason.
- Use separate `except` branches only when different exception types need different handling.
- If you only need the message text, use `getCurrentExceptionMsg()`.
- If you need the exception object, use `except X as e`.
- Compatibility note: `let e = getCurrentException()` inside the handler is equivalent. Use it when matching an established codebase.
- Do not add custom exception types unless callers handle them differently from existing ones.

## Helpers And APIs

- Bool-return parse helpers should catch `CatchableError` once and return `false`.
- For range-typed parameters such as `Positive`, trust the type for the basic domain and raise only for additional semantic bounds such as `pageNo > pages.len`.
- Use descriptive public names. Avoid generic names such as `Result`, `Data`, or `handleError`.
- Raise clear, bounded messages that identify the failed operation and keep the underlying reason.
- `{.noinline.}` on heavy error-message builders is an optimization, not a default rule. Use it only for hot wrappers that build large messages repeatedly.

## Cleanup And Retry

- Use `try/finally` for cleanup.
- Distinguish retriable failures from final failures before deciding whether to continue or raise.
- After the final retry failure, raise once with context.

# Workflow

1. Classify the code site.
   Internal step raises. Parse helper catches once. Module boundary translates. Orchestrator boundary records per-item output. Cleanup uses `finally`. Retry code classifies retriable vs final failure.
2. Keep the success path straight-line.
   If a proc just chains work such as `load -> build -> publish`, let failures propagate.
3. Translate only at real boundaries.
   Re-raise when you can add contract or subsystem context, for example `audit write failed for foo.log: ...`.
4. Shape public outputs at the orchestrator boundary.
   Record success and failure per item there instead of threading step-result objects through internal procs.
5. Verify the code shape with the repo tests.
   Run `nim c -r --mm:orc tests/nim-error-handling_verification/test_c23_positive_range_guard.nim` and `nim c -r --mm:orc tests/nim-error-handling_verification/test_c26_c27_exception_capture_styles.nim`, then run the rest of `tests/nim-error-handling_verification/test_*.nim`.

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
| Binding the exception object when only the message is needed | Adds noise when `getCurrentExceptionMsg()` is enough. |

# References

- `references/batch_preview_boundary.md`: End-to-end batch preview example with parse helper, translation boundary, and per-item orchestrator results.
- `references/retry_classification.md`: Retry loop example that separates retriable failures from final failures.

# Changelog

- 2026-04-09: Simplified the rule set, restored one default exception-binding pattern, and moved `getCurrentException()` to a compatibility note.
