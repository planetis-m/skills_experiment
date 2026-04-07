# C20: ensureMove(x) verifies the compiler can prove a move is legal.
# It rejects cases where implicit copy would be needed.

import std/assertions

type
  Val = object
    data: ptr int

proc `=destroy`*(x: var Val) =
  if x.data != nil:
    dealloc(x.data)
    x.data = nil

proc `=wasMoved`*(x: var Val) =
  x.data = nil

proc take(v: sink Val) =
  doAssert v.data != nil and v.data[] == 42

proc main() =
  # ensureMove with a function call result (rvalue) - always valid
  block:
    proc makeVal(): Val =
      result.data = create(int)
      result.data[] = 42
    take(ensureMove(makeVal()))
  
  echo "C20: PASS - ensureMove works with rvalues"

main()
