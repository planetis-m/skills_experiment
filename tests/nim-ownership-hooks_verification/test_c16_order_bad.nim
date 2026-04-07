# C16 NEGATIVE: proc using type BEFORE hooks should trigger compiler error.
# This file is expected to FAIL compilation.

type
  Buf = object
    data: ptr int

# Proc using Buf BEFORE hooks
proc useBuf(b: Buf): int =
  if b.data != nil: b.data[] else: 0

# Hooks declared AFTER proc
proc `=destroy`*(x: var Buf) =
  if x.data != nil:
    dealloc(x.data)
    x.data = nil

proc main() =
  var b: Buf
  b.data = create(int)
  b.data[] = 42
  doAssert useBuf(b) == 42
  echo "should not reach"
