# C16: Hooks must be declared before procs/generics that use the type, or compiler errors.
# Negative test: proc using the type BEFORE hooks should cause issues.

import std/assertions

type
  Buf = object
    data: ptr int

# Hooks declared FIRST - this should compile fine
proc `=destroy`*(x: var Buf) =
  if x.data != nil:
    dealloc(x.data)
    x.data = nil

proc `=wasMoved`*(x: var Buf) =
  x.data = nil

# Now a proc that uses Buf - fine because hooks already declared
proc useBuf(b: Buf): int =
  if b.data != nil: b.data[] else: 0

proc main() =
  var b: Buf
  b.data = create(int)
  b.data[] = 42
  doAssert useBuf(b) == 42
  echo "C16: PASS - hooks declared before use compiles correctly"

main()
