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
    raise newException(IOError, "document path must not be empty")
  result = Document(title: path, pages: @["Page 1 content"])
  if result.pages.len == 0:
    raise newException(IOError, "document has no pages")

proc renderPage*(doc: Document; pageIndex: int): seq[byte] =
  if pageIndex < 0 or pageIndex >= doc.pages.len:
    raise newException(ValueError, "pageIndex " & $pageIndex & " out of bounds (0.." & $(doc.pages.len - 1) & ")")
  result = rendererRender(doc.pages[pageIndex])
  if result.len == 0:
    raise newException(IOError, "rendered output for page " & $pageIndex & " is empty")

proc convertDocument*(path: string; format: string): seq[seq[byte]] =
  let doc = loadDocument(path)
  for i in 0..<doc.pages.len:
    result.add(renderPage(doc, i))

proc runBatch*(paths: seq[string]; format: string): seq[RenderResult] =
  for p in paths:
    try:
      let pages = convertDocument(p, format)
      var allBytes: seq[byte] = @[]
      for pageBytes in pages:
        allBytes.add(pageBytes)
      result.add(RenderResult(success: true, data: allBytes, errorMsg: ""))
    except CatchableError:
      result.add(RenderResult(success: false, data: @[], errorMsg: getCurrentExceptionMsg()))

proc tryParseInt*(s: string; value: var int): bool =
  result = false
  try:
    value = parseInt(s)
    result = true
  except CatchableError:
    result = false

proc raiseOSErrorHelper() =
  raise newException(OSError, "os failure")

proc translateError*() =
  try:
    raiseOSErrorHelper()
  except OSError:
    raise newException(IOError, "translation failed: " & getCurrentExceptionMsg())
