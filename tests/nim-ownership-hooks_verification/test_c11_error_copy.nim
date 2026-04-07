# C11: For move-only types, {.error.} on =copy prevents copying.

import std/assertions

type
  MoveOnly = object
    data: ptr int

proc `=destroy`*(x: var MoveOnly) =
  if x.data != nil:
    dealloc(x.data)
    x.data = nil

proc `=wasMoved`*(x: var MoveOnly) =
  x.data = nil

proc `=copy`*(dest: var MoveOnly; src: MoveOnly) {.error.}

proc main() =
  var a: MoveOnly
  a.data = create(int)
  a.data[] = 42
  
  var b = a  # move - should work
  doAssert b.data[] == 42
  
  # The following should NOT compile (uncomment to verify):
  # var c: MoveOnly
  # c = b  # copy - {.error.} prevents this
  
  echo "C11: PASS - {.error.} on =copy enforces move-only semantics"

main()
