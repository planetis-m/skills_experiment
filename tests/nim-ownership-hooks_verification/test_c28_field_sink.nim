# Test C28: Object and tuple fields are treated as separate entities for
# last-use analysis in sink parameter checking.

type
  Owned = object
    data: ptr int

var destroyCount = 0

proc `=destroy`*(x: Owned) =
  if x.data != nil:
    dealloc(x.data)
  inc destroyCount

proc `=wasMoved`*(x: var Owned) =
  x.data = nil

proc `=dup`*(x: Owned): Owned {.nodestroy.} =
  result = Owned(data: nil)
  if x.data != nil:
    result.data = create(int)
    result.data[] = x.data[]

proc consume(x: sink Owned) =
  discard x.data != nil

proc test() =
  # Tuple field independence: consume tup[0], tup[1] still alive
  destroyCount = 0
  var tup = (Owned(data: create(int)), Owned(data: create(int)))
  tup[0].data[] = 10
  tup[1].data[] = 20

  # Consume first field
  consume(tup[0])

  # Second field should still be accessible
  doAssert tup[1].data != nil
  doAssert tup[1].data[] == 20

  # Explicitly clean up tup[1] to avoid leak
  `=destroy`(tup[1])

  echo "C28: PASS"

test()
