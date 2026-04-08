## C09: "var overloads should not be added for simple scalar outputs such as
## int, float, bool, or enums."
##
## We demonstrate that returning `var int` from an accessor for a value-type
## field is misleading: the caller's mutation does NOT propagate back to the
## source object because Nim copies the value through the `var` return.

type
  Container = object
    x: int

# "Bad" accessor: returns var int for a scalar field.
# In ORC mode, Nim allows this because the field is addressable, but mutating
# the returned var does propagate since it's a direct field reference.
# The claim is that this is pointless/semantically misleading for scalars.

proc xMut(c: var Container): var int =
  result = c.x  # This returns a reference to the field

# "Good" accessor: plain value return for a scalar.
proc xVal(c: Container): int =
  result = c.x

block scalar_var_is_redundant_for_simple_use:
  ## A var int accessor is only useful if the caller intends to mutate the
  ## source field through the reference. For simple scalar outputs where
  ## mutation isn't part of the API contract, this is misleading because
  ## it suggests the caller should mutate, but scalar fields are usually
  ## set via dedicated setters or direct assignment.
  var c = Container(x: 42)
  doAssert xVal(c) == 42
  doAssert xMut(c) == 42

block var_accessor_does_propagate_but_is_misleading:
  ## Unlike what one might think, `var int` returned from a field reference
  ## DOES propagate mutations back. This makes it even more dangerous for
  ## scalar outputs: the accessor leaks mutable access to an internal field
  ## that the API designer likely didn't intend to expose mutably.
  var c = Container(x: 10)
  xMut(c) = 99
  doAssert c.x == 99, "var int accessor leaked mutable access to scalar field"
  ## This proves that `var` overloads for scalars are a design hazard:
  ## they expose mutation capability that shouldn't be part of a simple
  ## scalar getter API. The claim is correct: don't add var overloads for
  ## simple scalar outputs.

block value_accessor_is_safe:
  ## A plain value accessor returns a copy; mutation is impossible.
  var c = Container(x: 5)
  let v = xVal(c)
  # v is a copy — no way to mutate c through it
  doAssert v == 5
  doAssert c.x == 5

echo "C09: PASS"
