# C15: Compiler duplicates when sink argument has subsequent uses.
var copyCount = 0

type Val = object
  data: ptr int

proc `=destroy`*(x: var Val) =
  if x.data != nil:
    dealloc(x.data)
    x.data = nil

proc `=wasMoved`*(x: var Val) = x.data = nil

proc `=copy`*(dest: var Val; src: Val) =
  copyCount.inc()
  `=destroy`(dest)
  `=wasMoved`(dest)
  if src.data != nil:
    dest.data = create(int)
    dest.data[] = src.data[]

proc take(v: sink Val) = discard

proc main() =
  var a: Val
  a.data = create(int)
  a.data[] = 42
  take(a)
  doAssert a.data != nil
  doAssert a.data[] == 42
  echo "C15: PASS copyCount=", copyCount
main()
