# Test C02: opaque C handles as 'ptr object'
type
  OpaqueHandle {.incompleteStruct.} = object
  Handle = ptr OpaqueHandle

proc dummy(h: Handle): cint =
  if h == nil: discard
  result = 0

var h: Handle = nil
discard dummy(h)

echo "C02: PASS"
