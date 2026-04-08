# C23: Range-typed parameters already enforce their basic domain.

type
  Positive = range[1 .. high(int)]

proc buildPreviewPayload(pages: seq[string]; pageNo: Positive): string =
  if pageNo > pages.len:
    raise newException(ValueError, "page index out of bounds")
  result = pages[pageNo - 1]

proc test() =
  doAssert buildPreviewPayload(@["page-1"], Positive(1)) == "page-1"

  let zero = 0
  var caughtRange = false
  try:
    discard buildPreviewPayload(@["page-1"], Positive(zero))
  except RangeDefect:
    caughtRange = true
  doAssert caughtRange

  var caughtBounds = false
  try:
    discard buildPreviewPayload(@["page-1"], Positive(2))
  except ValueError:
    caughtBounds = true
  doAssert caughtBounds

test()
echo "C23: PASS"
