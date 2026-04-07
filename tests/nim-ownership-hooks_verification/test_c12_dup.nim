# C12: =dup with {.nodestroy.} as optimized duplication.
var dupCount = 0

type Buf = object
  data: ptr int

proc `=destroy`*(x: var Buf) =
  if x.data != nil:
    dealloc(x.data)
    x.data = nil

proc `=wasMoved`*(x: var Buf) = x.data = nil

proc `=dup`*(src: Buf): Buf {.nodestroy.} =
  dupCount.inc()
  result = Buf(data: nil)
  if src.data != nil:
    result.data = create(int)
    result.data[] = src.data[]

proc main() =
  var a: Buf
  a.data = create(int)
  a.data[] = 42
  var b = `=dup`(a)
  doAssert b.data[] == 42
  doAssert b.data != a.data
  doAssert dupCount == 1
  echo "C12: PASS"
main()
