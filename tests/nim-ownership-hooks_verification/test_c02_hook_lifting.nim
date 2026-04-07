# C02: Compiler lifts hooks through nesting. If a field's type has custom hooks, the enclosing type gets correct hooks for free.

import std/assertions

var destroyCount = 0

type
  Inner = object
    data: ptr int
  
  Outer = object
    inner: Inner

proc `=destroy`*(x: var Inner) =
  if x.data != nil:
    destroyCount.inc()
    dealloc(x.data)
    x.data = nil

proc `=wasMoved`*(x: var Inner) =
  x.data = nil

proc `=copy`*(dest: var Inner; src: Inner) {.error.}

proc newInner(val: int): Inner =
  result.data = create(int)
  result.data[] = val

proc main() =
  block:
    var o = Outer(inner: newInner(42))
    doAssert o.inner.data[] == 42
    # Let o go out of scope - Outer should get auto-generated destroy that calls Inner's =destroy
  doAssert destroyCount == 1, "Expected 1 destroy, got " & $destroyCount
  echo "C02: PASS - compiler lifts hooks through nesting"

main()
