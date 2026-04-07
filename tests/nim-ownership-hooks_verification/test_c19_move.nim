# C19: move(x) forces move semantics.

import std/assertions

var destroyed = 0

type
  Val = object
    data: ptr int

proc `=destroy`*(x: var Val) =
  if x.data != nil:
    destroyed.inc()
    dealloc(x.data)
    x.data = nil

proc `=wasMoved`*(x: var Val) =
  x.data = nil

proc `=copy`*(dest: var Val; src: Val) =
  `=destroy`(dest)
  `=wasMoved`(dest)
  if src.data != nil:
    dest.data = create(int)
    dest.data[] = src.data[]

proc main() =
  var a: Val
  a.data = create(int)
  a.data[] = 42
  
  var b = move(a)
  doAssert b.data != nil
  doAssert b.data[] == 42
  doAssert a.data == nil  # a is moved-from
  echo "C19: PASS - move(x) forces move semantics"

main()
