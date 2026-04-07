# C06+C07: Sentinel check in destroy. wasMoved makes destroy a no-op.
var destroyCalled = 0
var actualFree = 0

type Buf = object
  data: ptr int

proc `=destroy`*(x: var Buf) =
  destroyCalled.inc()
  if x.data != nil:
    actualFree.inc()
    dealloc(x.data)
    x.data = nil

proc `=wasMoved`*(x: var Buf) = x.data = nil
proc `=copy`*(dest: var Buf; src: Buf) {.error.}

proc main() =
  block:
    var b: Buf
    b.data = create(int)
    b.data[] = 1
  doAssert destroyCalled == 1 and actualFree == 1
  block:
    var b: Buf
    b.data = create(int)
    `=wasMoved`(b)
    doAssert b.data == nil
  doAssert destroyCalled == 2 and actualFree == 1
  echo "C06+C07: PASS"
main()
