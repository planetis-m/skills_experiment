# C24: When custom =sink dest has fields not fully overwritten, use wasMoved before rebuild.
type Buf = object
  data: ptr int
  extra: int

proc `=destroy`*(x: var Buf) =
  if x.data != nil:
    dealloc(x.data)
    x.data = nil

proc `=wasMoved`*(x: var Buf) =
  x.data = nil
  x.extra = 0

proc `=sink`*(dest: var Buf; src: Buf) =
  `=destroy`(dest)
  `=wasMoved`(dest)  # reset ALL fields including extra
  dest.data = src.data
  dest.extra = src.extra

proc `=copy`*(dest: var Buf; src: Buf) {.error.}

proc main() =
  var a: Buf
  a.data = create(int)
  a.data[] = 42
  a.extra = 7
  var b: Buf
  b.data = create(int)
  b.data[] = 99
  b.extra = 3
  b = a
  doAssert b.data[] == 42
  doAssert b.extra == 7
  echo "C24: PASS"
main()
