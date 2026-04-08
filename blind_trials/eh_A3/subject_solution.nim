import std/[strutils, sequtils]

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
    raise newException(IOError, "path must not be empty")
  result = Document(title: path, pages: @[path & "_page0", path & "_page1"])
  if result.pages.len == 0:
    raise newException(IOError, "document has no pages")

proc renderPage*(doc: Document; pageIndex: int): seq[byte] =
  if pageIndex < 0 or pageIndex >= doc.pages.len:
    raise newException(ValueError, "pageIndex " & $pageIndex & " out of bounds for document with " & $doc.pages.len & " pages")
  result = rendererRender(doc.pages[pageIndex])
  if result.len == 0:
    raise newException(IOError, "rendered output for page " & $pageIndex & " is empty")

proc flattenBytes(chunks: seq[seq[byte]]): seq[byte] =
  let total = chunks.mapIt(it.len).foldl(a + b)
  result = newSeq[byte](total)
  var offset = 0
  for chunk in chunks:
    if chunk.len > 0:
      copyMem(result[offset].addr, chunk[0].unsafeAddr, chunk.len)
      offset += chunk.len

proc convertDocument*(path: string; format: string): seq[seq[byte]] =
  let doc = loadDocument(path)
  result = newSeq[seq[byte]](doc.pages.len)
  for i in 0..<doc.pages.len:
    result[i] = renderPage(doc, i)

proc runBatch*(paths: seq[string]; format: string): seq[RenderResult] =
  result = newSeq[RenderResult](paths.len)
  for i in 0..<paths.len:
    try:
      let pages = convertDocument(paths[i], format)
      result[i] = RenderResult(success: true, data: flattenBytes(pages), errorMsg: "")
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
  raise newException(OSError, "simulated OS failure")

proc translateError*() =
  try:
    raiseOSErrorHelper()
  except OSError:
    raise newException(IOError, "translation failed: " & getCurrentExceptionMsg())
