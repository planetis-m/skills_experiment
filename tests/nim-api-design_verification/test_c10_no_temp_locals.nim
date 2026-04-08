## C10: "In lent and var accessors, temporary locals should be avoided in
## favor of direct indexing from the owner object because temporaries can
## trigger escaping-borrow issues."
##
## The temp-local pattern is in a separate file (test_c10_temp_local_fail.nim)
## to demonstrate it fails to compile. This file tests the correct pattern.

import std/assertions

type
  Data = object
    items: seq[string]

# Safe pattern: direct indexing from the owner object
proc itemDirect(d: Data; i: int): lent string =
  doAssert i >= 0 and i < d.items.len, "index out of bounds"
  result = d.items[i]  # direct field indexing — no temp local

block direct_indexing_lent_works:
  let d = Data(items: @["hello", "world", "test"])
  let ref1 = itemDirect(d, 0)
  doAssert ref1 == "hello"
  let ref2 = itemDirect(d, 2)
  doAssert ref2 == "test"
  # Multiple borrows from same owner are fine with direct indexing
  doAssert itemDirect(d, 1) == "world"

block direct_indexing_var_accessor:
  ## var accessor with direct indexing — safe and idiomatic
  proc itemMut(d: var Data; i: int): var string =
    doAssert i >= 0 and i < d.items.len, "index out of bounds"
    result = d.items[i]  # direct field indexing

  var d = Data(items: @["alpha", "beta", "gamma"])
  itemMut(d, 1) = "BETA"
  doAssert d.items[1] == "BETA", "var accessor with direct indexing should work"
  doAssert d.items[0] == "alpha"

block direct_indexing_nested_field:
  ## Direct indexing works even with nested structures
  type
    Inner = object
      vals: seq[int]
    Outer = object
      inner: Inner

  proc valDirect(o: Outer; i: int): lent int =
    doAssert i >= 0 and i < o.inner.vals.len
    result = o.inner.vals[i]

  let o = Outer(inner: Inner(vals: @[10, 20, 30]))
  doAssert valDirect(o, 0) == 10
  doAssert valDirect(o, 2) == 30

echo "C10: PASS"
