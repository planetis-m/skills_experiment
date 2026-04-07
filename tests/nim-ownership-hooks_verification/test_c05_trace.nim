# C05: =trace compiles under ORC for cycle-capable manually allocated containers.

import std/assertions

var traceCalled = false

type
  Node = ref object
    val: int

  Container = object
    items: ptr UncheckedArray[Node]
    len: int

proc `=destroy`*(x: var Container) =
  if x.items != nil:
    dealloc(x.items)
    x.items = nil

proc `=wasMoved`*(x: var Container) =
  x.items = nil
  x.len = 0

proc `=trace`*(x: var Container; env: pointer) =
  traceCalled = true
  if x.items != nil:
    for i in 0..<x.len:
      `=trace`(x.items[i], env)

proc main() =
  var c: Container
  c.len = 1
  c.items = cast[ptr UncheckedArray[Node]](alloc(sizeof(Node)))
  c.items[0] = Node(val: 42)
  `=trace`(c, nil)
  doAssert traceCalled
  `=destroy`(c)
  echo "C05: PASS - =trace compiles under ORC"

main()
