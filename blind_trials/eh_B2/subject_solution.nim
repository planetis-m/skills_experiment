import std/strutils

type
  Document* = object
    title*: string
    pages*: seq[string]

  RenderResult* = object
    success*: bool
    data*: seq[byte]
    errorMsg*: string

  ConversionJob* = object
    id*: int
    format*: string

proc rendererRender(pageContent: string): seq[byte] =
  if pageContent.len == 0:
    return @[]
  result = newSeq[byte](pageContent.len)
  for i in 0..<pageContent.len:
    result[i] = byte(pageContent[i])

proc loadDocument*(path: string): Document =
  if path.len == 0:
    raise newException(IOError, "path is empty")

proc renderPage*(doc: Document; pageIndex: int): seq[byte] =
  if pageIndex < 0 or pageIndex >= doc.pages.len:
    raise newException(ValueError, "pageIndex out of bounds: " & $pageIndex)
  result = rendererRender(doc.pages[pageIndex])
  if result.len == 0:
    raise newException(IOError, "rendered output is empty for page " & $pageIndex)

proc convertDocument*(path: string; format: string): seq[seq[byte]] =
  let doc = loadDocument(path)
  for i in 0..<doc.pages.len:
    result.add(renderPage(doc, i))

proc runBatch*(paths: seq[string]; format: string): seq[RenderResult] =
  for p in paths:
    try:
      let pages = convertDocument(p, format)
      var combined = newSeq[byte]()
      for pageBytes in pages:
        for b in pageBytes:
          combined.add(b)
      result.add(RenderResult(success: true, data: combined))
    except CatchableError:
      result.add(RenderResult(success: false, errorMsg: getCurrentExceptionMsg()))

proc tryParseInt*(s: string; value: var int): bool =
  result = false
  try:
    value = parseInt(s)
    result = true
  except CatchableError:
    result = false

proc helperThatRaisesOSError() =
  raise newException(OSError, "underlying OS failure")

proc translateError*() =
  try:
    helperThatRaisesOSError()
  except OSError:
    raise newException(IOError, "translation failed: " & getCurrentExceptionMsg())
