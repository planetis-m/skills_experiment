type
  Inner = object
    val: int
    destroyed: ptr bool

  Outer = object
    data: ptr UncheckedArray[Inner]
    len: int

proc `=destroy`*(x: Inner) =
  if x.destroyed != nil:
    x.destroyed[] = true

proc `=wasMoved`*(x: var Inner) =
  x.destroyed = nil

proc `=destroy`*(x: Outer) =
  if x.data != nil:
    for i in 0..<x.len:
      `=destroy`(x.data[i])
    dealloc(x.data)

proc `=wasMoved`*(x: var Outer) =
  x.data = nil
  x.len = 0

block:
  var flag = false
  var o = Outer(len: 1, data: nil)
  o.data = cast[ptr UncheckedArray[Inner]](alloc(sizeof(Inner)))
  o.data[0] = Inner(val: 42, destroyed: addr flag)
  `=destroy`(o)
  `=wasMoved`(o)
  doAssert flag, "Nested element should have been destroyed before dealloc"
  echo "C41: PASS"
