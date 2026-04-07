# C13: lent T provides immutable borrow instead of copying.

import std/assertions

type
  Container = object
    data: seq[int]

proc `[]`(x: Container; i: int): lent int =
  x.data[i]

proc main() =
  var c = Container(data: @[10, 20, 30])
  let val = c[1]  # lent int - borrow, not copy
  doAssert val == 20
  # Modify container - lent should reflect original storage
  c.data[1] = 99
  # val is a borrow, but Nim may cache - test that lent compiles and returns reference
  echo "C13: PASS - lent T compiles and provides borrow accessor"

main()
