# C08: Compiler synthesizes =sink from =destroy + raw move. No custom =sink needed.
var destroyCount = 0

type Buf = object
  data: ptr int

proc `=destroy`*(x: var Buf) =
  if x.data != nil:
    destroyCount.inc()
    dealloc(x.data)
    x.data = nil

proc `=wasMoved`*(x: var Buf) = x.data = nil
proc `=copy`*(dest: var Buf; src: Buf) {.error.}

proc main() =
  var a: Buf
  a.data = create(int)
  a.data[] = 42
  var b = a
  doAssert b.data[] == 42
  var c: Buf
  c.data = create(int)
  c.data[] = 99
  b = c
  doAssert destroyCount == 1
  doAssert b.data[] == 99
  echo "C08: PASS"
main()
