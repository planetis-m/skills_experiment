# C02: Compiler lifts hooks through nesting. Inner's hooks called via Outer's auto-generated hooks.
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

proc `=wasMoved`*(x: var Inner) = x.data = nil
proc `=copy`*(dest: var Inner; src: Inner) {.error.}

proc newInner(val: int): Inner =
  result.data = create(int)
  result.data[] = val

proc main() =
  block:
    var o = Outer(inner: newInner(42))
    doAssert o.inner.data[] == 42
  doAssert destroyCount == 1
  echo "C02: PASS"
main()
