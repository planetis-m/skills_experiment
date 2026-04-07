# C14: sink parameters are affine — callee may consume or not.
var destroyed = 0

type Val = object
  data: ptr int

proc `=destroy`*(x: var Val) =
  if x.data != nil:
    destroyed.inc()
    dealloc(x.data)
    x.data = nil

proc `=wasMoved`*(x: var Val) = x.data = nil

proc consume(v: sink Val) = discard
proc maybeConsume(v: sink Val) = discard

proc main() =
  block:
    var a: Val
    a.data = create(int)
    a.data[] = 1
    consume(a)
  doAssert destroyed == 1
  block:
    var b: Val
    b.data = create(int)
    b.data[] = 2
    maybeConsume(b)
  doAssert destroyed == 2
  echo "C14: PASS"
main()
