type
  Thing = object
    a: int
    b: int
    data: ptr int
    extra: int

proc `=destroy`*(x: Thing) =
  if x.data != nil:
    dealloc(x.data)

proc `=wasMoved`*(x: var Thing) =
  x.data = nil
  x.a = 0
  x.b = 0
  x.extra = 0

proc `=sink`*(dest: var Thing; src: Thing) =
  `=destroy`(dest)
  `=wasMoved`(dest)
  dest.a = src.a
  dest.b = src.b
  dest.data = src.data
  dest.extra = src.extra

block:
  var d = Thing(a: 1, b: 2, data: cast[ptr int](alloc(sizeof(int))), extra: 99)
  d.data[] = 10
  var s = Thing(a: 5, b: 6, data: nil, extra: 0)
  `=sink`(d, s)
  doAssert d.a == 5
  doAssert d.b == 6
  doAssert d.data == nil
  doAssert d.extra == 0, "extra should be 0 after =wasMoved reset, got " & $d.extra
  echo "C44: PASS"
