# Test C25: opaque handles as pointer or ptr OpaqueObj
type
  OpaqueObj = object
  Handle = ptr OpaqueObj

proc useHandle(h: Handle): cint =
  if h == nil: discard
  result = 0

var h: Handle = nil
discard useHandle(h)

# Also works as plain pointer
type Handle2 = pointer
var h2: Handle2 = nil
discard h2

echo "C25: PASS"
