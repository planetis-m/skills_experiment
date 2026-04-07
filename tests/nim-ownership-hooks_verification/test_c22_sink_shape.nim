# C22: =sink canonical shape: destroy dest, transfer fields. No wasMoved in sink body.
# Also verify: do NOT add self-assignment check.
var sinkCalls = 0

type Buf = object
  data: ptr int

proc `=destroy`*(x: var Buf) =
  if x.data != nil:
    dealloc(x.data)
    x.data = nil

proc `=wasMoved`*(x: var Buf) = x.data = nil

proc `=sink`*(dest: var Buf; src: Buf) =
  sinkCalls.inc()
  `=destroy`(dest)
  # No =wasMoved here — direct transfer
  dest.data = src.data

proc `=copy`*(dest: var Buf; src: Buf) =
  if dest.data != src.data:
    `=destroy`(dest)
    `=wasMoved`(dest)
    if src.data != nil:
      dest.data = create(int)
      dest.data[] = src.data[]

proc main() =
  var a: Buf
  a.data = create(int)
  a.data[] = 10
  var b: Buf
  b.data = create(int)
  b.data[] = 20
  b = a  # sink
  doAssert sinkCalls >= 1
  echo "C22: PASS"
main()
