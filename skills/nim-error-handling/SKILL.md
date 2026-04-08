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
- `CatchableError` is the base for all recoverable exceptions. Use it as the catch-all for recoverable errors. Do not catch bare `Exception` — that also catches `Defect` (unrecoverable bugs like `AccessViolationDefect`).

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

### Propagate through steps, catch at boundary

Intermediate steps raise on invalid output. The orchestrator catches at the boundary where errors become actionable.

```nim
proc renderPageBitmap(page: int): Bitmap =
  result = rendererRender(page)
  if result.width <= 0 or result.height <= 0 or result.pixels.isNil:
    raise newException(IOError, "invalid bitmap state from renderer")

proc encodePageBitmap(bitmap: Bitmap): seq[byte] =
  result = encodeWebp(bitmap)
  if result.len == 0:
    raise newException(IOError, "encoded WebP output was empty")

proc buildPageTask(page: int): PageTask =
  let bitmap = renderPageBitmap(page)      # raises on failure
  let webpBytes = encodePageBitmap(bitmap) # raises on failure
  result = PageTask(page: page, webpBytes: webpBytes)

proc runOrchestrator(pages: seq[int]) =
  for page in pages:
    try:
      submit(buildPageTask(page))
    except CatchableError:
      recordPageFailure(page, getCurrentExceptionMsg())
```

### Bool-return parse helper

```nim
proc parseFirstCallArgs*[T](x: ChatCreateResult; dst: var T; i = 0): bool =
  result = false
  try:
    dst = fromJson(x.firstCallArgs(i), T)
    result = true
  except CatchableError:
    result = false
```

### Exception translation at module boundaries

```nim
try:
  discard doWork()
except CatchableError:
  raise newException(IOError, "doWork failed: " & getCurrentExceptionMsg())
```

### Separate except branches for different handling

When different error types need different recovery, catch them separately:

```nim
try:
  let webp = renderPageToWebp(doc, pageNumber, cfg)
  state.cachedPayloads[seqId] = CachedPayload(webpBytes: webp)
except IOError:
  state.staged[seqId] = errorPageResult(page, 1, PdfError, getCurrentExceptionMsg())
except ValueError:
  state.staged[seqId] = errorPageResult(page, 1, EncodeError, getCurrentExceptionMsg())
```

Multiple types can share a handler:

```nim
try:
  url = nc.createUrl(name)
except ValueError, IOError, OSError:
  warn nimbleFile, "cannot resolve: ", getCurrentExceptionMsg()
```

### Error classification for pipelines

When pipeline items can fail independently, use typed error enums and structured results — not exceptions — for per-item outcomes. The orchestrator catches exceptions and records them as structured data.

```nim
type
  PageErrorKind = enum
    NoError, PdfError, EncodeError, NetworkError, Timeout, RateLimit, HttpError

  PageResult = object
    page: int
    status: PageResultStatus  # Pending, Ok, Error
    errorKind: PageErrorKind
    errorMessage: string

proc classifyFinalError(item: RequestResult): FinalError =
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

Use `{.noinline.}` on error-raising procs that build complex messages — avoids duplicating the message-construction code at every call site.

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

proc loadDocument*(path: string): PdfDocument =
  result.raw = FPDF_LoadDocument(path.cstring, cstring(""))
  if pointer(result.raw) == nil:
    raisePdfiumError("FPDF_LoadDocument failed")
```

### Resource cleanup with try/finally

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

### Catch with `as` to access the exception object

```nim
try:
  createDir(name)
except OSError as e:
  error name, "Failed to create directory: " & e.msg
```

### Retry with classification

Distinguish retriable from final errors. On final failure, raise — don't silently return.

```nim
proc requestWithRetry(client: Relay; cfg: Config; text: sink string): seq[float32] =
  var attempt = 1
  while true:
    let item = client.makeRequest(buildRequest(cfg, text))
    if shouldRetry(item, attempt, maxAttempts):
      inc attempt
      sleep(retryDelayMs(rng, attempt, retryPolicy))
    else:
      if item.error.kind != teNone or not isHttpSuccess(item.response.code):
        let finalError = classifyFinalError(item)
        raise newException(IOError, finalError.message)
      return parseResult(item)
```

## Changelog
- 2026-04-08: Initial version
- 2026-04-08: Added patterns from real codebases: separate except branches, error classification, {.noinline.} error procs, C library translation, try/finally cleanup, catch-as binding, retry classification, multi-type except
