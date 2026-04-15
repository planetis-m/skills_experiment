type
  Counted = object
    val: int
    dupCount: ptr int

  Bag = object
    items: ptr UncheckedArray[Counted]
    len: int

proc `=destroy`*(x: Counted) = discard

proc `=wasMoved`*(x: var Counted) =
  x.dupCount = nil

proc `=dup`*(x: Counted): Counted =
  result = x
  if x.dupCount != nil:
    inc x.dupCount[]

proc `=destroy`*(b: Bag) =
  if b.items != nil:
    dealloc(b.items)

proc `=wasMoved`*(b: var Bag) =
  b.items = nil
  b.len = 0

proc `=dup`*(b: Bag): Bag {.nodestroy.} =
  result = Bag(len: b.len, items: nil)
  if b.items != nil and b.len > 0:
    result.items = cast[ptr UncheckedArray[Counted]](alloc(b.len * sizeof(Counted)))
    for i in 0..<b.len:
      result.items[i] = `=dup`(b.items[i])

block:
  var dupCounter = 0
  var b = Bag(len: 1, items: cast[ptr UncheckedArray[Counted]](alloc(sizeof(Counted))))
  b.items[0] = Counted(val: 42, dupCount: addr dupCounter)
  var b2 = `=dup`(b)
  doAssert dupCounter == 1, "Child =dup should have been called once, got " & $dupCounter
  doAssert b2.items[0].val == 42
  dealloc(b2.items)
  dealloc(b.items)
  echo "C42: PASS"
