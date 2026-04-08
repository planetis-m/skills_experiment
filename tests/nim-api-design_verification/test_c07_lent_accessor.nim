## C07: Read accessors that borrow from object fields should use lent T.

type
  Holder = object
    data: seq[int]

proc dataRef(h: Holder): lent seq[int] =
  result = h.data

proc itemRef(h: Holder; i: int): lent int =
  result = h.data[i]

proc dataRefMut(h: var Holder): var seq[int] =
  result = h.data

block lent_returns_correct_values:
  let h = Holder(data: @[10, 20, 30])
  doAssert h.dataRef().len == 3
  doAssert h.itemRef(0) == 10
  doAssert h.itemRef(2) == 30

block lent_borrows_read_only:
  let h = Holder(data: @[7, 8, 9])
  let val = h.itemRef(0)
  doAssert val == 7
  var sum = 0
  for v in h.dataRef():
    sum += v
  doAssert sum == 24

block var_allows_mutation_lent_does_not:
  var h = Holder(data: @[100])
  h.dataRefMut()[0] = 200
  doAssert h.data[0] == 200
  doAssert h.dataRef()[0] == 200

block lent_works_on_let_holders:
  let h = Holder(data: @[1, 2, 3])
  doAssert h.dataRef().len == 3
  doAssert h.itemRef(2) == 3

echo "C07: PASS"
