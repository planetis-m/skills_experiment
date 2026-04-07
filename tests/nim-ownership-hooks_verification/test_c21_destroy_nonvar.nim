# C21: =destroy takes T (not var T). Cannot assign to fields inside destroy.
# This tests that destroy with non-var parameter compiles.
type Obj = object
  data: ptr int

proc `=destroy`*(x: Obj) =
  # x is not var, so we can read but not write fields
  if x.data != nil:
    dealloc(x.data)  # dealloc takes pointer by value, fine

proc `=wasMoved`*(x: var Obj) = x.data = nil

proc main() =
  var a: Obj
  a.data = create(int)
  a.data[] = 42
  var b = a
  doAssert b.data[] == 42
  echo "C21: PASS"
main()
