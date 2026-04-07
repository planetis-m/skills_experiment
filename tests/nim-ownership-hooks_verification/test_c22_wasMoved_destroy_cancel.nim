# Test C22: =wasMoved(x) followed by =destroy(x) cancel each other out.
# The compiler eliminates the destroy call entirely after wasMoved.
# This is the "destructor removal" optimization from the official docs.

type
  Inner = object
    data: ptr int

var destroyCount = 0

proc `=destroy`*(x: Inner) =
  if x.data != nil:
    dealloc(x.data)
  inc destroyCount

proc `=wasMoved`*(x: var Inner) =
  x.data = nil

proc `=dup`*(x: Inner): Inner {.nodestroy.} =
  result = Inner(data: nil)
  if x.data != nil:
    result.data = create(int)
    result.data[] = x.data[]

proc `=copy`*(dest: var Inner; src: Inner) =
  if dest.data == src.data: return
  `=destroy`(dest)
  `=wasMoved`(dest)
  if src.data != nil:
    dest.data = create(int)
    dest.data[] = src.data[]
  else:
    dest.data = nil

proc test() =
  # Normal case: destroy called when variable goes out of scope
  destroyCount = 0
  block:
    var a = Inner(data: create(int))
    a.data[] = 42
    # a goes out of scope, compiler inserts =destroy
  doAssert destroyCount == 1, "Expected 1 destroy, got " & $destroyCount

  # wasMoved case: compiler ELIMINATES the destroy call entirely
  # This is the destructor removal optimization (C22)
  destroyCount = 0
  block:
    var b = Inner(data: create(int))
    b.data[] = 99
    `=wasMoved`(b)
    # b goes out of scope, but compiler sees wasMoved and skips destroy
  doAssert destroyCount == 0, "Expected 0 destroys (eliminated), got " & $destroyCount

  echo "C22: PASS"

test()
