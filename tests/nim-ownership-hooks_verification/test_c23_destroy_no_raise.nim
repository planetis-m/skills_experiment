# Test C23: =destroy is implicitly .raises: []
# A destructor should not raise exceptions. The compiler enforces or warns about this.

import std/exitprocs

type
  SafeObj = object
    data: ptr int

proc `=destroy`*(x: SafeObj) =
  if x.data != nil:
    dealloc(x.data)

proc `=wasMoved`*(x: var SafeObj) =
  x.data = nil

proc `=dup`*(x: SafeObj): SafeObj {.nodestroy.} =
  result = SafeObj(data: nil)
  if x.data != nil:
    result.data = create(int)
    result.data[] = x.data[]

proc `=copy`*(dest: var SafeObj; src: SafeObj) =
  if dest.data == src.data: return
  `=destroy`(dest)
  `=wasMoved`(dest)
  if src.data != nil:
    dest.data = create(int)
    dest.data[] = src.data[]
  else:
    dest.data = nil

proc test() =
  var a = SafeObj(data: create(int))
  a.data[] = 99
  var b = a  # copy
  doAssert b.data != nil
  doAssert b.data[] == 99
  # destruction happens at end of scope, no exceptions
  echo "C23: PASS"

test()
