# C23: =copy deep-copy shape: self-assign check, destroy, wasMoved, then clone.
type Buf = object
  data: ptr int

proc `=destroy`*(x: var Buf) =
  if x.data != nil:
    dealloc(x.data)
    x.data = nil

proc `=wasMoved`*(x: var Buf) = x.data = nil

proc `=copy`*(dest: var Buf; src: Buf) =
  if dest.data == src.data: return  # self-assign guard
  `=destroy`(dest)
  `=wasMoved`(dest)
  if src.data != nil:
    dest.data = create(int)
    dest.data[] = src.data[]

proc main() =
  var a: Buf
  a.data = create(int)
  a.data[] = 42
  # Deep copy
  var b: Buf
  b = a
  doAssert b.data != a.data  # independent
  doAssert b.data[] == 42
  # Mutate b, a unchanged
  b.data[] = 99
  doAssert a.data[] == 42
  doAssert b.data[] == 99
  # Self-copy
  var c: Buf
  c.data = create(int)
  c.data[] = 77
  c = c
  doAssert c.data[] == 77
  echo "C23: PASS"
main()
