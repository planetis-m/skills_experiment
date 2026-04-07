# C03: Custom hooks needed for raw pointers. Without =destroy, raw pointer memory leaks.
# Test: type with ptr to alloc'd memory, verify =destroy frees it.

import std/assertions

var freed = false

type
  RawOwner = object
    p: ptr int

proc `=destroy`*(x: var RawOwner) =
  if x.p != nil:
    freed = true
    dealloc(x.p)
    x.p = nil

proc `=wasMoved`*(x: var RawOwner) =
  x.p = nil

proc `=copy`*(dest: var RawOwner; src: RawOwner) {.error.}

proc main() =
  block:
    var r: RawOwner
    r.p = create(int)
    r.p[] = 99
    doAssert r.p[] == 99
  doAssert freed, "=destroy was not called or did not free"
  echo "C03: PASS - custom =destroy needed and works for raw pointer ownership"

main()
