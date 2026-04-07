# C03: Custom hooks needed for raw pointers. Without =destroy, memory leaks.
# Test: verify custom =destroy frees the pointer.
var freed = false

type RawOwner = object
  p: ptr int

proc `=destroy`*(x: var RawOwner) =
  if x.p != nil:
    freed = true
    dealloc(x.p)
    x.p = nil

proc `=wasMoved`*(x: var RawOwner) = x.p = nil
proc `=copy`*(dest: var RawOwner; src: RawOwner) {.error.}

proc main() =
  block:
    var r: RawOwner
    r.p = create(int)
    r.p[] = 99
  doAssert freed
  echo "C03: PASS"
main()
