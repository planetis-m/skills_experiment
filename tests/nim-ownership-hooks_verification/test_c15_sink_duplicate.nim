# C15: If compiler cannot prove last use for sink param, it may duplicate before passing.

import std/assertions

var copyCount = 0

type
  Val = object
    data: ptr int

proc `=destroy`*(x: var Val) =
  if x.data != nil:
    dealloc(x.data)
    x.data = nil

proc `=wasMoved`*(x: var Val) =
  x.data = nil

proc `=copy`*(dest: var Val; src: Val) =
  copyCount.inc()
  `=destroy`(dest)
  `=wasMoved`(dest)
  if src.data != nil:
    dest.data = create(int)
    dest.data[] = src.data[]

proc take(v: sink Val) =
  discard

proc main() =
  var a: Val
  a.data = create(int)
  a.data[] = 42
  
  # Use a after passing to sink - compiler must copy
  take(a)
  # a might still be used below, so compiler may copy instead of move
  doAssert a.data != nil  # if copied, a is still valid
  doAssert a.data[] == 42
  
  echo "C15: PASS - compiler duplicates when last use cannot be proven (copyCount=", copyCount, ")"

main()
