# C06+C07: =destroy checks moved-from sentinel. =wasMoved resets fields to make =destroy a no-op.

import std/assertions

var destroyCalled = 0
var actualFree = 0

type
  Buf = object
    data: ptr int

proc `=destroy`*(x: var Buf) =
  destroyCalled.inc()
  if x.data != nil:  # sentinel check
    actualFree.inc()
    dealloc(x.data)
    x.data = nil

proc `=wasMoved`*(x: var Buf) =
  x.data = nil

proc `=copy`*(dest: var Buf; src: Buf) {.error.}

proc main() =
  # Normal destroy
  block:
    var b: Buf
    b.data = create(int)
    b.data[] = 1
  doAssert destroyCalled == 1 and actualFree == 1
  
  # wasMoved then destroy should be no-op
  block:
    var b: Buf
    b.data = create(int)
    `=wasMoved`(b)
    doAssert b.data == nil
  doAssert destroyCalled == 2 and actualFree == 1, "wasMoved should make destroy a no-op"
  
  echo "C06+C07: PASS - sentinel check and wasMoved work correctly"

main()
