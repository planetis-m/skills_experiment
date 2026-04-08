---
name: nim-error-handling
description: Design Nim exception boundaries, translation, cleanup, and parse-failure behavior.
---

# Nim Error Handling

Use this skill when deciding where exceptions should be raised, caught, translated, or turned into structured output.

## Rules

- Bubble errors by default. Internal step functions should raise and let failures propagate until a real boundary.
- Catch only when you can recover, translate the error, or turn it into actionable output.
- Use `CatchableError` as the recoverable catch-all. Do not catch bare `Exception`.
- Use specific exception types such as `IOError`, `ValueError`, and `OSError` when the caller should distinguish them.
- Do not pass ad-hoc step result objects between internal functions just to avoid exceptions.
- Use structured result objects only at orchestrator boundaries where each item needs its own success or failure record.
- Bool-return parse helpers should catch `CatchableError` once and return `false`.
- Translate low-level errors at module boundaries with `getCurrentExceptionMsg()` so the caller gets the original reason plus local context.
- Use separate `except` branches only when different error types need different handling. Otherwise share one branch.
- Use `try/finally` for cleanup. `except` is for error handling, not resource release.
- On final retry failure, raise a descriptive exception. Do not silently return a partial failure.
- Use `except X as e` only when you need fields from the exception object itself.
- `{.noinline.}` on heavy error-message builders is an optimization, not a default rule. Use it only for hot wrappers that build large messages repeatedly.

## Workflow

1. Classify the code site.

| Site | Default behavior |
|------|------------------|
| Internal step | Raise a specific exception. Do not catch locally. |
| Bool-return parse helper | Catch `CatchableError` once and return `false`. |
| Module boundary | Catch and re-raise with context. |
| Orchestrator boundary | Catch `CatchableError` and record structured failure output. |
| Cleanup path | Use `finally`. |
| Retry loop | Classify retriable vs final failure, then raise on final failure. |

2. Raise at the step level, catch at the boundary.

```nim
proc renderPage(doc: Document; pageIndex: int): seq[byte] =
  if pageIndex < 0 or pageIndex >= doc.pages.len:
    raise newException(ValueError, "page index out of bounds")
  result = rendererRender(doc.pages[pageIndex])
  if result.len == 0:
    raise newException(IOError, "rendered output was empty")

proc runBatch(paths: seq[string]): seq[RenderResult] =
  result = newSeq[RenderResult](paths.len)
  for i, path in paths:
    try:
      let pages = convertDocument(path)
      result[i] = RenderResult(success: true, data: flatten(pages), errorMsg: "")
    except CatchableError:
      result[i] = RenderResult(success: false, data: @[], errorMsg: getCurrentExceptionMsg())
```

3. Use the helper patterns only where they fit.

```nim
proc tryParseInt(s: string; value: var int): bool =
  result = false
  try:
    value = parseInt(s)
    result = true
  except CatchableError:
    result = false

proc translateError() =
  try:
    lowLevelWork()
  except OSError:
    raise newException(IOError, "translation failed: " & getCurrentExceptionMsg())
```

4. Verify the shape of the code.
- No bare `Exception` catches.
- No empty `except` blocks.
- Internal step functions do not catch just to repackage locally.
- Boundary functions return structured failure output or re-raise with context.
- Cleanup uses `finally`.

## Common Mistakes

| Mistake | Why it is wrong |
|---------|-----------------|
| Catching in every layer | Hides the real boundary and makes failures harder to reason about. |
| Catching bare `Exception` | Also catches `Defect`, which is not recoverable application flow. |
| Passing `ok/kind/message` objects between steps | Reimplements exception propagation with more boilerplate and less information. |
| Swallowing an exception | Loses the failure without recovery or reporting. |
| Using `try/except` for cleanup | Cleanup belongs in `finally`, whether an exception happened or not. |
| Adding custom exception types with no distinct handling | Adds type noise without changing behavior. |
| Returning quietly after retries are exhausted | Hides final failure from the caller. |

## Changelog
- 2026-04-08: Initial version
- 2026-04-08: Simplified into a deterministic rule-and-workflow guide
