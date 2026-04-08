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
  # Simulate loading: return a document with pages derived from the path
  result = Document(title: path, pages: @[path & "_page0", path & "_page1"])
  if result.pages.len == 0:
    raise newException(IOError, "document has no pages")

proc renderPage*(doc: Document; pageIndex: int): seq[byte] =
  if pageIndex < 0 or pageIndex >= doc.pages.len:
    raise newException(ValueError, "pageIndex out of bounds: " & $pageIndex)
  result = rendererRender(doc.pages[pageIndex])
  if result.len == 0:
    raise newException(IOError, "rendered output is empty for page " & $pageIndex)

proc convertDocument*(path: string; format: string): seq[seq[byte]] =
  let doc = loadDocument(path)
  result = newSeq[seq[byte]](doc.pages.len)
  for i in 0..<doc.pages.len:
    result[i] = renderPage(doc, i)

proc runBatch*(paths: seq[string]; format: string): seq[RenderResult] =
  result = newSeq[RenderResult](paths.len)
  for i in 0..<paths.len:
    try:
      let data = convertDocument(paths[i], format)
      var flattened = newSeq[byte]()
      for pageBytes in data:
        flattened.add(pageBytes)
      result[i] = RenderResult(success: true, data: flattened, errorMsg: "")
    except CatchableError:
      result[i] = RenderResult(success: false, data: @[], errorMsg: getCurrentExceptionMsg())

proc tryParseInt*(s: string; value: var int): bool =
  result = false
  try:
    value = parseInt(s)
    result = true
  except CatchableError:
    result = false

proc raiseOSErrorHelper() =
  raise newException(OSError, "underlying OS error")

proc translateError*() =
  try:
    raiseOSErrorHelper()
  except OSError:
    raise newException(IOError, "translation failed: " & getCurrentExceptionMsg())
