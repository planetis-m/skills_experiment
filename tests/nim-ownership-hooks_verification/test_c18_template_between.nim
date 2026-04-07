# C18: Templates safely appear between type and hooks.
type Buf = object
  data: ptr int

template dataSize(b: Buf): int =
  if b.data != nil: 1 else: 0

proc `=destroy`*(x: var Buf) =
  if x.data != nil:
    dealloc(x.data)
    x.data = nil

proc `=wasMoved`*(x: var Buf) = x.data = nil

proc main() =
  var b: Buf
  b.data = create(int)
  b.data[] = 42
  doAssert dataSize(b) == 1
  echo "C18: PASS"
main()
