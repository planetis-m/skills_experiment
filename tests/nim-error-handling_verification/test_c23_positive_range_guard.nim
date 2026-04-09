# C23: Positive belongs at the boundary; internal helpers use int.

proc buildPreviewPayload(pages: seq[string]; pageIndex: int): string =
  if pageIndex >= pages.len:
    raise newException(ValueError, "page index out of bounds")
  result = pages[pageIndex]

proc renderPreview(pages: seq[string]; pageNo: Positive): string =
  buildPreviewPayload(pages, pageNo.int - 1)

proc test() =
  doAssert renderPreview(@["page-1"], Positive(1)) == "page-1"

  let zero = 0
  var caughtRange = false
  try:
    discard renderPreview(@["page-1"], Positive(zero))
  except RangeDefect:
    caughtRange = true
  doAssert caughtRange

  var caughtBounds = false
  try:
    discard renderPreview(@["page-1"], Positive(2))
  except ValueError:
    caughtBounds = true
  doAssert caughtBounds

test()
echo "C23: PASS"
