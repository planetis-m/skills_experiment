# C36/C37/C38/C40: Refcounted handle with inverted counter pattern.

var freeCalls = 0

type
  Payload = object
    counter: int
    value: int

  Handle = object
    p: ptr Payload

proc freePayload(p: ptr Payload) =
  freeCalls.inc()
  dealloc(p)

proc makeHandle(value: int): Handle =
  result.p = create(Payload)
  result.p.counter = 0
  result.p.value = value

proc `=destroy`*(x: Handle) =
  if x.p != nil:
    if x.p.counter == 0:
      freePayload(x.p)
    else:
      dec x.p.counter

proc `=wasMoved`*(x: var Handle) =
  x.p = nil

template share(dest, src) =
  if src.p != nil:
    inc src.p.counter
  dest.p = src.p

proc `=dup`*(src: Handle): Handle =
  share(result, src)

proc `=copy`*(dest: var Handle; src: Handle) =
  `=destroy`(dest)
  share(dest, src)

proc main() =
  block:
    freeCalls = 0
    var a = makeHandle(7)
    doAssert a.p.counter == 0

    var b = `=dup`(a)
    doAssert b.p == a.p
    doAssert a.p.counter == 1

    `=destroy`(b)
    `=wasMoved`(b)
    doAssert a.p.counter == 0

    `=destroy`(a)
    `=wasMoved`(a)
    doAssert freeCalls == 1

  block:
    freeCalls = 0
    var a = makeHandle(11)
    var b = a
    doAssert a.p == b.p
    doAssert a.p.counter == 1

    a = b
    doAssert a.p == b.p
    doAssert a.p.counter == 1
    doAssert a.p.value == 11

    `=destroy`(a)
    `=wasMoved`(a)
    doAssert b.p.counter == 0
    doAssert freeCalls == 0

    `=destroy`(b)
    `=wasMoved`(b)
    doAssert freeCalls == 1

  echo "C36/C37/C38/C40: PASS"

main()
