## C10: In lent/var accessors, use direct indexing — temp locals cause
##       "escapes its stack frame" errors under ORC.
## See test_c10_temp_local_fail.nim for the compile-failure proof.

type
  Data = object
    items: seq[string]

proc itemDirect(d: Data; i: int): lent string =
  result = d.items[i]  # direct indexing — safe

block direct_indexing_works:
  let d = Data(items: @["hello", "world"])
  doAssert itemDirect(d, 0) == "hello"
  doAssert itemDirect(d, 1) == "world"

block nested_direct_indexing:
  type
    Inner = object
      vals: seq[int]
    Outer = object
      inner: Inner

  proc valRef(o: Outer; i: int): lent int =
    result = o.inner.vals[i]  # nested direct indexing — safe

  let o = Outer(inner: Inner(vals: @[10, 20, 30]))
  doAssert valRef(o, 0) == 10
  doAssert valRef(o, 2) == 30

echo "C10: PASS"
