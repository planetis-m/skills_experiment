# Test C34: =destroy(x: T) vs =destroy(x: var T) — both compile,
# but the non-var form is preferred as it prevents accidental field mutation.

type
  FormA = object
    data: ptr int

  FormB = object
    data: ptr int

# Non-var form (preferred)
proc `=destroy`*(x: FormA) =
  if x.data != nil:
    dealloc(x.data)

# Var form (also compiles)
proc `=destroy`*(x: var FormB) =
  if x.data != nil:
    dealloc(x.data)
    x.data = nil  # This compiles with var T but would not with T

proc `=wasMoved`*(x: var FormA) =
  x.data = nil

proc `=wasMoved`*(x: var FormB) =
  x.data = nil

proc test() =
  var a = FormA(data: create(int))
  a.data[] = 1
  var b = FormB(data: create(int))
  b.data[] = 2

  # Both forms compile and destroy correctly
  # FormA uses non-var destroy (cannot mutate fields)
  # FormB uses var destroy (can mutate fields, but that's =wasMoved's job)
  doAssert a.data != nil
  doAssert b.data != nil

  echo "C34: PASS"

test()
