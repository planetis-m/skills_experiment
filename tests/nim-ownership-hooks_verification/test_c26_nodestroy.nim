# Test C26: {.nodestroy.} pragma inhibits all hook injections
# Inside a {.nodestroy.} proc, the compiler does not insert =destroy calls.

type
  Tracked = object
    data: ptr int

var destroyCount = 0

proc `=destroy`*(x: Tracked) =
  if x.data != nil:
    dealloc(x.data)
  inc destroyCount

proc `=wasMoved`*(x: var Tracked) =
  x.data = nil

proc `=dup`*(x: Tracked): Tracked {.nodestroy.} =
  result = Tracked(data: nil)
  if x.data != nil:
    result.data = create(int)
    result.data[] = x.data[]

proc `=copy`*(dest: var Tracked; src: Tracked) =
  if dest.data == src.data: return
  `=destroy`(dest)
  `=wasMoved`(dest)
  if src.data != nil:
    dest.data = create(int)
    dest.data[] = src.data[]
  else:
    dest.data = nil

# Without nodestroy: creating a local and letting it go out of scope calls =destroy
proc withDestroy() =
  destroyCount = 0
  var a = Tracked(data: create(int))
  a.data[] = 1
  discard a  # use it
  # a goes out of scope, =destroy called
  # we check after the proc returns

# With nodestroy: no implicit =destroy calls
proc withoutDestroy() {.nodestroy.} =
  var a = Tracked(data: create(int))
  a.data[] = 2
  # a goes out of scope, but NO =destroy called
  # This leaks! But that's what nodestroy means.

proc test() =
  # Test normal behavior first
  destroyCount = 0
  withDestroy()
  let normalCount = destroyCount
  doAssert normalCount >= 1, "Expected at least 1 destroy in normal proc, got " & $normalCount

  # Test nodestroy behavior
  destroyCount = 0
  withoutDestroy()
  let noDestroyCount = destroyCount
  doAssert noDestroyCount == 0, "Expected 0 destroys in nodestroy proc, got " & $noDestroyCount

  echo "C26: PASS"

test()
