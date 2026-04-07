# C11: {.error.} on =copy prevents copying at compile-time.
type MoveOnly = object
  data: ptr int

proc `=destroy`*(x: var MoveOnly) =
  if x.data != nil:
    dealloc(x.data)
    x.data = nil

proc `=wasMoved`*(x: var MoveOnly) = x.data = nil
proc `=copy`*(dest: var MoveOnly; src: MoveOnly) {.error.}

proc main() =
  var a: MoveOnly
  a.data = create(int)
  a.data[] = 42
  var b = a
  doAssert b.data[] == 42
  echo "C11: PASS"
main()
