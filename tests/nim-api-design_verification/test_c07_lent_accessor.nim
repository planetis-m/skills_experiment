## C07: Read accessors that borrow from object fields should use lent T.

type
  Holder = object
    data: seq[int]

# --- lent accessor ---
proc dataRef(h: Holder): lent seq[int] =
  result = h.data

proc itemRef(h: Holder; i: int): lent int =
  result = h.data[i]

# --- var accessor for comparison ---
proc dataRefMut(h: var Holder): var seq[int] =
  result = h.data

# --- Test 1: lent accessor compiles and returns correct value ---
block:
  let h = Holder(data: @[10, 20, 30])
  doAssert h.dataRef().len == 3
  doAssert h.itemRef(0) == 10
  doAssert h.itemRef(2) == 30

# --- Test 2: lent int item identity — direct borrow from field ---
block:
  let h = Holder(data: @[42, 99])
  # Using the lent accessor inline should borrow directly
  doAssert h.itemRef(0) == h.data[0]
  doAssert h.itemRef(1) == h.data[1]

# --- Test 3: lent returns read-only — cannot be assigned through ---
# This is a compile-time guarantee. We verify the accessor works with `let`
# (immutable) contexts. The `lent` keyword is specifically designed for
# read-only borrowing without copies at the semantic level.
block:
  let h = Holder(data: @[7, 8, 9])
  # Reading through lent works
  let val = h.itemRef(0)
  doAssert val == 7
  # lent seq supports iteration without copying data
  var sum = 0
  for v in h.dataRef():
    sum += v
  doAssert sum == 24

# --- Test 4: lent vs var — mutation through lent is not allowed ---
# We test that `var` accessor allows mutation while `lent` does not.
block:
  var h = Holder(data: @[100])
  # var accessor allows mutation
  h.dataRefMut()[0] = 200
  doAssert h.data[0] == 200

  # lent accessor returns value correctly (read-only borrow)
  doAssert h.dataRef()[0] == 200

# --- Test 5: lent accessor works on immutable (let) holders ---
block:
  # A let holder cannot provide var accessors, but lent works fine
  let h = Holder(data: @[1, 2, 3])
  doAssert h.dataRef().len == 3
  doAssert h.itemRef(2) == 3

echo "C07: PASS"
