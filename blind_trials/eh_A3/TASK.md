# Task: Implement a batch preview smoke-test program with proper error handling

Create a file called `subject_solution.nim` that implements a small but non-trivial program the judge can inspect for good and bad error-handling patterns.

The point of this task is not only whether the code compiles. The judge should be able to inspect the structure for anti-patterns such as:
- mixing exception propagation with ad-hoc step result objects
- catching and re-raising without adding useful context
- wrapping every raising call in local `try/except`
- adding many separate `except` branches when the handling is identical
- Python-style argument validation for range-typed parameters such as `Positive`

## Required public types

```nim
type
  PreviewItem* = object
    path*: string
    success*: bool
    previewId*: string
    errorMsg*: string

  BatchSummary* = object
    okCount*: int
    failCount*: int
    items*: seq[PreviewItem]
```

Do not add other result-like public types for intermediate steps.

## Required helper procs

Include these helpers exactly or with equivalent behavior:

```nim
proc fakeReadPages(path: string): seq[string] =
  if path.len == 0:
    raise newException(IOError, "path is empty")
  case path
  of "missing":
    raise newException(IOError, "document missing")
  of "blank":
    result = @[""]
  else:
    result = @[path & "-page-1", path & "-page-2"]

proc fakeUpload(payload: seq[byte]): string =
  if payload.len == 0:
    raise newException(OSError, "upload payload empty")
  result = "preview-" & $payload.len

proc fakeAuditWrite(auditPath: string; line: string) =
  if auditPath == "audit-fail":
    raise newException(OSError, "audit write failed")
```

## Required public procs

1. `parseRetryLimit*(s: string; value: var Positive): bool`
   Parse a retry limit. Return `true` on success and `false` on invalid input. Use the bool-return parse-helper pattern.

2. `loadPages*(path: string): seq[string]`
   Load pages by calling `fakeReadPages`. Let load failures propagate.

3. `buildPreviewPayload*(pages: seq[string]; pageNo: Positive): seq[byte]`
   Build bytes for one page.
   - Raise `ValueError` if `pageNo` is greater than `pages.len`
   - Raise `IOError` if the selected page produces empty output
   - Do not add `pageNo <= 0` checks because `pageNo` is already `Positive`

4. `publishPreview*(payload: seq[byte]): string`
   Publish a preview by calling `fakeUpload`. Let publish failures propagate.

5. `processOne*(path: string; pageNo: Positive): string`
   Chain `loadPages`, `buildPreviewPayload`, and `publishPreview`.
   This is an internal success-path proc. Let failures propagate. Do not catch here.

6. `writeAuditLine*(auditPath: string; line: string)`
   Call `fakeAuditWrite`.
   Catch `OSError` here and re-raise as `IOError` with added context using `getCurrentExceptionMsg()`.
   This is the one place in the task where translation is expected.

7. `runBatch*(paths: seq[string]; pageNo: Positive; retryLimit: Positive; auditPath: string): BatchSummary`
   Process each path.
   - Catch `CatchableError` at this boundary
   - Record one `PreviewItem` per input path
   - Successful items must carry `success=true`, non-empty `previewId`, and empty `errorMsg`
   - Failed items must carry `success=false`, empty `previewId`, and non-empty `errorMsg`
   - Update `okCount` and `failCount`
   - Use `writeAuditLine` only when a failure needs to be recorded in the audit log

## Required smoke run

Add a `when isMainModule:` block that:
- exercises `parseRetryLimit` on one valid and one invalid input
- runs `runBatch(@["good", "missing", "blank"], 1, 2, "audit.log")`
- prints a short success marker such as `SMOKE: PASS`

## Critical requirements

- Do not introduce ad-hoc step result objects such as `StepResult`, `OkOrError`, or `ResultInfo`
- Do not catch exceptions in `loadPages`, `buildPreviewPayload`, `publishPreview`, or `processOne`
- Do not catch and re-raise the same exception type unless you add real boundary context
- Use `CatchableError`, not bare `Exception`
- Use separate `except` branches only when the handling is actually different
- Do not validate `pageNo <= 0` or `retryLimit <= 0` and raise manually; those inputs are already typed as `Positive`
- Use descriptive names for public boundary/result procs and types; avoid generic names like `Result`, `Data`, or `handleError`
- Compile with `nim c --mm:orc`

## Judge checklist

The judge should score these checks by reading the code and running the compile command:

- compiles with `nim c --mm:orc`
- `parseRetryLimit` uses the bool-return parse-helper pattern
- `processOne` is a straight-line success path with no local catch
- `writeAuditLine` is the only translation boundary and it adds useful context
- `runBatch` is the main catch boundary and returns one `PreviewItem` per input
- successful items carry a non-empty `previewId`
- failed items carry a non-empty `errorMsg`
- no ad-hoc intermediate result types were introduced
- no pointless `Positive` argument validation was added
- no repetitive local `try/except` wrappers were added around every raising call

After writing, verify it compiles:

```bash
nim c --mm:orc subject_solution.nim
```
