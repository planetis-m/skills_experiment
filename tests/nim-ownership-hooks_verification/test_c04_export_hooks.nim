# C04: Export custom ownership hooks. Missing export should cause issues or be detectable.
# Test: unexported hooks still compile but may not be called in all contexts (cross-module).
# In single-file, unexported hooks still work, but the skill says to export them.
# We verify that exported hooks compile and work correctly.

import std/assertions

var destroyed = false

type
  Exported = object
    p: ptr int

proc `=destroy`*(x: var Exported) =
  if x.p != nil:
    destroyed = true
    dealloc(x.p)

proc `=wasMoved`*(x: var Exported) =
  x.p = nil

proc main() =
  var e: Exported
  e.p = create(int)
  e.p[] = 1
  # move
  var e2 = e
  # e is moved-from
  doAssert destroyed == false # old e2 has no alloc yet... actually e2 took ownership
  # Now destroy e2
  `=destroy`(e2)
  doAssert destroyed
  echo "C04: PASS - exported hooks compile and function"

main()
