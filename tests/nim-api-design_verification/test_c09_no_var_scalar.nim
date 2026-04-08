## C09: var overloads should not be added for simple scalar outputs (int, float,
##       bool, enums) — they leak mutable access to internal state.

type
  Container = object
    x: int

proc xMut(c: var Container): var int =
  result = c.x  # returns a reference to the field

proc xVal(c: Container): int =
  result = c.x

block both_return_correct_value:
  var c = Container(x: 42)
  doAssert xVal(c) == 42
  doAssert xMut(c) == 42

block var_int_propagates_back:
  ## var int from a direct field reference DOES propagate mutations back.
  ## This makes it a design hazard: it leaks mutable access to internal state
  ## that the API designer likely didn't intend to expose.
  var c = Container(x: 10)
  xMut(c) = 99
  doAssert c.x == 99, "var int accessor leaked mutable access to scalar field"

block value_accessor_is_safe:
  var c = Container(x: 5)
  let v = xVal(c)  # copy — no way to mutate c through it
  doAssert v == 5
  doAssert c.x == 5

echo "C09: PASS"
