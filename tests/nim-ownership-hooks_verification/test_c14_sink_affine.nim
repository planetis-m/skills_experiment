# C14: sink parameters are affine - callee may consume value once or not at all.

import std/assertions

var destroyed = 0

type
  Val = object
    data: ptr int

proc `=destroy`*(x: var Val) =
  if x.data != nil:
    destroyed.inc()
    dealloc(x.data)
    x.data = nil

proc `=wasMoved`*(x: var Val) =
  x.data = nil

proc consume(v: sink Val) =
  # We consume it - it will be destroyed at end of scope
  doAssert v.data != nil
  discard

proc maybeConsume(v: sink Val) =
  # We don't consume it - just read
  doAssert v.data != nil
  # v is still destroyed at end of scope by the compiler

proc main() =
  block:
    var a: Val
    a.data = create(int)
    a.data[] = 1
    consume(a)
    # a is moved-from
  
  doAssert destroyed == 1
  
  block:
    var b: Val
    b.data = create(int)
    b.data[] = 2
    maybeConsume(b)
  
  doAssert destroyed == 2
  echo "C14: PASS - sink parameters work as affine (consumed or not)"

main()
