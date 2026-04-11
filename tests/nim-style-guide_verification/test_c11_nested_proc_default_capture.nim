## C11: nested procs may capture outer locals by default

proc makeCounter(start: int): proc(): int =
  var current = start

  proc nextValue(): int =
    inc current
    current

  result = nextValue

let counter = makeCounter(10)
doAssert counter() == 11
doAssert counter() == 12

echo "C11: PASS"
