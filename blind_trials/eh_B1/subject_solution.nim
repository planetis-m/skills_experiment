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
  result = Document(title: path, pages: @["page1", "page2"])
  if result.pages.len == 0:
    raise newException(IOError, "document has no pages")

proc renderPage*(doc: Document; pageIndex: int): seq[byte] =
  if pageIndex < 0 or pageIndex >= doc.pages.len:
    raise newException(ValueError, "pageIndex " & $pageIndex & " out of bounds for document with " & $doc.pages.len & " pages")
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
      let pages = convertDocument(paths[i], format)
      var allBytes: seq[byte] = @[]
      for pageBytes in pages:
        allBytes.add(pageBytes)
      result[i] = RenderResult(success: true, data: allBytes, errorMsg: "")
    except CatchableError:
      result[i] = RenderResult(success: false, data: @[], errorMsg: getCurrentExceptionMsg())

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
