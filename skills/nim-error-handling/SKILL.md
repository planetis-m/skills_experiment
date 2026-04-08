---
name: nim-error-handling
description: Design Nim error propagation, exception boundaries, and parse-failure behavior.
---

# Nim Error Handling

Use this skill when choosing between exceptions, boundary translation, parse helpers,
or multi-step pipeline failure handling.

## Core rules

- Do not introduce ad-hoc result objects that pass only `ok`, `kind`, and `message` between steps.
- Do not add custom exception types unless callers handle them differently from existing exceptions.
- Catch errors only where you can recover, translate across a boundary, or add required context.
- Raise clear, bounded, actionable errors.
- Do not silently swallow exceptions.
- Prefer exception propagation over manual result-wrapper plumbing for recoverable errors.
- Let stepwise pipeline errors bubble until the boundary where they become actionable output.
- Convert low-level errors at module boundaries when needed for context or contracts.
- For bool-return parse helpers, catch `CatchableError` once at the helper boundary and return `false`.

## Additional rules from real-world patterns

### Raising errors

- Use specific exception types (`IOError`, `ValueError`, `OSError`) with descriptive messages via `newException`. Include the operation name, the failure reason, and any relevant codes.
- Guard resource creation: check for nil/empty results and raise immediately.
- Validate output from processing steps — raise if results are invalid (empty, zero-length, mismatched dimensions).
- Use `{.noinline.}` on error-raising procs that format complex messages (e.g., translate C library error codes) to avoid code bloat at every call site.

### Catching errors

- `CatchableError` is the base for all recoverable exceptions. Use it as the catch-all. Do not catch bare `Exception` — that also catches `Defect` (unrecoverable bugs).
- Use specific `except` branches (`IOError`, `ValueError`) when different errors need different handling in the same `try` block.
- `getCurrentExceptionMsg()` returns the message of the currently caught exception. Use it for context when translating.

### Pipeline and batch patterns

- Return structured results (with status enum) from pipeline orchestrators — not intermediate steps. Intermediate steps should raise; the orchestrator catches and records per-item.
- Never let exceptions escape a batch/orchestrator boundary — catch and record per-item.
- Classify errors into typed enums for structured error reporting and retry/failure decisions.
- Distinguish retriable from final errors — classify before deciding retry vs. fail.
- On final failure after retries, raise a descriptive exception (not silently return).

### Resource cleanup

- Use `try`/`finally` for resource cleanup, not `try`/`except`. Reserve `except` for actual error handling.
- Use `defer` for cleanup of resources acquired in the same scope.

### Config and parse helpers

- Gracefully handle missing/invalid config files — warn and continue with defaults rather than crash.
- For bool-return parse helpers, catch `CatchableError` once at the helper boundary and return `false`.

## Don't

```nim
type
  StepResult = object
    ok: bool
    kind: string
    message: string

proc renderPage(): StepResult =
  discard
```

## Do

```nim
type
  Bitmap = object
    width: int
    height: int
    pixels: pointer

  PageTask = object
    page: int
    webpBytes: seq[byte]

proc renderPageBitmap(page: int): Bitmap =
  result = rendererRender(page)
  if result.width <= 0 or result.height <= 0 or result.pixels.isNil:
    raise newException(IOError, "invalid bitmap state from renderer")

proc encodePageBitmap(bitmap: Bitmap): seq[byte] =
  result = encodeWebp(bitmap)
  if result.len == 0:
    raise newException(IOError, "encoded WebP output was empty")

proc buildPageTask(page: int): PageTask =
  let bitmap = renderPageBitmap(page)
  let webpBytes = encodePageBitmap(bitmap)
  result = PageTask(page: page, webpBytes: webpBytes)

proc runOrchestrator(pages: seq[int]) =
  for page in pages:
    try:
      submit(buildPageTask(page))
    except CatchableError:
      recordPageFailure(page, boundedErrorMessage(getCurrentExceptionMsg()))

proc parseFirstCallArgs*[T](x: ChatCreateResult; dst: var T; i = 0): bool =
  result = false
  try:
    dst = fromJson(x.firstCallArgs(i), T)
    result = true
  except CatchableError:
    result = false
```

```nim
try:
  discard doWork()
except CatchableError:
  raise newException(IOError, "doWork failed: " & getCurrentExceptionMsg())
```

### Error classification for pipelines

```nim
type
  PageErrorKind* = enum
    NoError, PdfError, EncodeError, NetworkError, Timeout, RateLimit, HttpError

proc classifyFinalError*(item: RequestResult): FinalError =
  if item.error.kind != teNone:
    let kind = case item.error.kind
      of teTimeout: Timeout
      else: NetworkError
    result = FinalError(kind: kind, message: item.error.message)
  else:
    let code = item.response.code
    if code == 429:
      result = FinalError(kind: RateLimit, message: "rate limited (http 429)")
    elif code == 408 or code == 504:
      result = FinalError(kind: Timeout, message: "request timed out")
    else:
      result = FinalError(kind: HttpError, message: "http status " & $code)
```

### C library error translation

```nim
proc raisePdfiumError*(context: string) {.noinline.} =
  let code = FPDF_GetLastError()
  let detail = case code
    of 0: "no error"
    of 2: "file not found or could not be opened"
    of 3: "file not in PDF format or corrupted"
    of 4: "password required or incorrect password"
    else: "unknown"
  raise newException(IOError, context & ": " & detail & " (code " & $code & ")")
```

### Separate except branches for different handling

```nim
try:
  let webp = renderPageToWebp(doc, pageNumber, cfg.renderConfig)
  state.cachedPayloads[seqId] = CachedPayload(webpBytes: webp)
except IOError:
  state.staged[seqId] = errorPageResult(page, 1, PdfError, getCurrentExceptionMsg())
except ValueError:
  state.staged[seqId] = errorPageResult(page, 1, EncodeError, getCurrentExceptionMsg())
```

### Resource cleanup with finally

```nim
var stmt: SqlPrepared
try:
  stmt = db.prepare(query)
  for row in db.instantRows(stmt):
    result.add(readSearchResult(row))
finally:
  if not stmt.isNil:
    stmt.finalize()
```

## Changelog
- 2026-04-08: Initial version (human-written)
- 2026-04-08: Added rules from chunktts, pdfocr, chunkvec codebases: error classification, {.noinline.} for error procs, C library error translation, separate except branches, pipeline orchestrator pattern, resource cleanup with finally, config fallbacks, retry boundary pattern
