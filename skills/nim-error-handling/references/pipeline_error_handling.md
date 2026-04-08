# Multi-step pipeline with boundary catch

A pipeline where each step can fail, but errors are only caught at the orchestrator level.

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
  let bitmap = renderPageBitmap(page)      # raises on failure
  let webpBytes = encodePageBitmap(bitmap) # raises on failure
  result = PageTask(page: page, webpBytes: webpBytes)

proc runOrchestrator(pages: seq[int]) =
  for page in pages:
    try:
      submit(buildPageTask(page))
    except CatchableError:
      recordPageFailure(page, boundedErrorMessage(getCurrentExceptionMsg()))
```

Key points:
- Steps raise on invalid output — no intermediate catching.
- `buildPageTask` chains steps; any failure propagates.
- Only `runOrchestrator` catches, where it can record and continue.
