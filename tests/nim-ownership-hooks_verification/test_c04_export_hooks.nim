# C04: Exported hooks work. Unexported hooks also compile in single module but may fail cross-module.
# Positive test: exported hooks compile and function.
var destroyed = false

type Exp = object
  p: ptr int

proc `=destroy`*(x: var Exp) =
  if x.p != nil:
    destroyed = true
    dealloc(x.p)

proc `=wasMoved`*(x: var Exp) = x.p = nil

proc main() =
  var e: Exp
  e.p = create(int)
  e.p[] = 1
  var e2 = e
  `=destroy`(e2)
  doAssert destroyed
  echo "C04: PASS"
main()
