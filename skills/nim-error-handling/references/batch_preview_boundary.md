Batch-preview example showing a bool parse helper, one translation boundary, and an orchestrator catch boundary.

```nim
import std/[strutils]

type
  Positive = range[1 .. high(int)]

  PreviewItem = object
    path: string
    success: bool
    previewId: string
    errorMsg: string

  BatchSummary = object
    okCount: int
    failCount: int
    items: seq[PreviewItem]

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

proc parseRetryLimit(s: string; value: var Positive): bool =
  result = false
  try:
    let parsed = parseInt(s)
    if parsed notin Positive:
      return false
    value = Positive(parsed)
    result = true
  except CatchableError:
    result = false

proc loadPages(path: string): seq[string] =
  fakeReadPages(path)

proc buildPreviewPayload(pages: seq[string]; pageNo: Positive): seq[byte] =
  if pageNo > pages.len:
    raise newException(ValueError, "page index out of bounds")
  let page = pages[pageNo - 1]
  if page.len == 0:
    raise newException(IOError, "selected page was empty")
  result = cast[seq[byte]](page.toOpenArrayByte(0, page.high))

proc publishPreview(payload: seq[byte]): string =
  fakeUpload(payload)

proc processOne(path: string; pageNo: Positive): string =
  let pages = loadPages(path)
  let payload = buildPreviewPayload(pages, pageNo)
  result = publishPreview(payload)

proc writeAuditLine(auditPath: string; line: string) =
  try:
    fakeAuditWrite(auditPath, line)
  except OSError:
    raise newException(IOError, "audit write failed for " & auditPath & ": " &
        getCurrentExceptionMsg())

proc runBatch(paths: seq[string]; pageNo: Positive; auditPath: string): BatchSummary =
  result.items = @[]
  for path in paths:
    try:
      let previewId = processOne(path, pageNo)
      result.items.add PreviewItem(
        path: path,
        success: true,
        previewId: previewId,
        errorMsg: ""
      )
      inc result.okCount
    except CatchableError:
      let msg = getCurrentExceptionMsg()
      writeAuditLine(auditPath, path & ": " & msg)
      result.items.add PreviewItem(
        path: path,
        success: false,
        previewId: "",
        errorMsg: msg
      )
      inc result.failCount
```

Key points
- `processOne` stays straight-line and lets failures propagate.
- `writeAuditLine` is the one translation boundary because it adds local audit context.
- `runBatch` is the place where exceptions become per-item output.
