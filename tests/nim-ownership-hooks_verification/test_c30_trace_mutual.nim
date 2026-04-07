# Test C30: =trace has a mutual use problem with =destroy.
# Forward-declare both to prevent conflicts.

var traceCount = 0
var destroyCount = 0

type
  Node = object
    value: int
    next: ptr Node

  Cyclic = object
    head: ptr Node

# Forward declarations to avoid mutual-use conflicts
proc `=destroy`*(x: Cyclic)
proc `=trace`*(x: var Cyclic; env: pointer)

proc `=destroy`*(x: Cyclic) =
  if x.head != nil:
    var cur = x.head
    while cur != nil:
      let nxt = cur.next
      dealloc(cur)
      cur = nxt
  inc destroyCount

proc `=trace`*(x: var Cyclic; env: pointer) =
  inc traceCount

proc `=wasMoved`*(x: var Cyclic) =
  x.head = nil

proc `=dup`*(x: Cyclic): Cyclic {.nodestroy.} =
  result = Cyclic(head: nil)

proc `=copy`*(dest: var Cyclic; src: Cyclic) =
  if dest.head == src.head: return
  `=destroy`(dest)
  `=wasMoved`(dest)
  dest.head = src.head

proc test() =
  let nodeSize = sizeof(int) + sizeof(ptr Node)
  var node = cast[ptr Node](alloc(nodeSize))
  node.value = 42
  node.next = nil

  var c = Cyclic(head: node)
  destroyCount = 0

  doAssert c.head != nil
  doAssert c.head.value == 42

  # Move c to d to avoid double-free
  var d = c
  `=wasMoved`(c)

  # d destroyed at end of scope
  echo "C30: PASS"

test()
