# Test C51: ergonomic wrapper converts C return codes to Nim exceptions
type
  RawHandle = object

proc libOpen(path: cstring): ptr RawHandle =
  result = nil  # simulate failure

type
  Handle = object
    raw: ptr RawHandle

proc open(path: string): Handle =
  result.raw = libOpen(path.cstring)
  if result.raw.isNil:
    raise newException(IOError, "open failed")

try:
  discard open("nonexistent")
  doAssert false, "should have raised"
except IOError:
  discard  # expected

echo "C51: PASS"
