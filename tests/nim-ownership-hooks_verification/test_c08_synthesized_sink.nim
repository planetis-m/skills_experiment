# C08: Compiler can synthesize =sink from =destroy + raw move. No custom =sink needed by default.

import std/assertions

var destroyCount = 0

type
  Buf = object
    data: ptr int

proc `=destroy`*(x: var Buf) =
  if x.data != nil:
    destroyCount.inc()
    dealloc(x.data)
    x.data = nil

proc `=wasMoved`*(x: var Buf) =
  x.data = nil

proc `=copy`*(dest: var Buf; src: Buf) {.error.}

proc main() =
  var a: Buf
  a.data = create(int)
  a.data[] = 42
  
  # Sink via move - compiler synthesizes =sink
  var b = a  # move
  
  doAssert b.data != nil
  doAssert b.data[] == 42
  
  # Now overwrite b with a new value to test synthesized sink destroys old
  var c: Buf
  c.data = create(int)
  c.data[] = 99
  b = c  # synthesized =sink: destroys old b, moves c into b
  
  doAssert destroyCount == 1  # old b's data freed
  doAssert b.data[] == 99
  
  echo "C08: PASS - compiler-synthesized =sink works from =destroy"

main()
