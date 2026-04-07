# C12: =dup with {.nodestroy.} as optimized duplication path.

import std/assertions

var dupCount = 0

type
  Buf = object
    data: ptr int
    len: int

proc `=destroy`*(x: var Buf) =
  if x.data != nil:
    dealloc(x.data)
    x.data = nil

proc `=wasMoved`*(x: var Buf) =
  x.data = nil

proc `=dup`*(src: Buf): Buf {.nodestroy.} =
  dupCount.inc()
  result = Buf(data: nil, len: src.len)
  if src.data != nil:
    result.data = create(int)
    result.data[] = src.data[]

proc main() =
  var a: Buf
  a.data = create(int)
  a.data[] = 42
  a.len = 1
  
  # Use =dup via clone-like pattern
  # In ARC/ORC, `let b = a` might use =dup for certain expressions
  # Direct call to test:
  var b = `=dup`(a)
  doAssert b.data != nil
  doAssert b.data[] == 42
  doAssert b.data != a.data  # independent copy
  doAssert dupCount == 1
  
  echo "C12: PASS - =dup with nodestroy works as optimized duplication"

main()
