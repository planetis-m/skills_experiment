# C36/C37/C38/C40: Refcounted handle with standard dec-then-check pattern.

var freeCalls = 0

type
  Payload = object
    rc: int
    value: int

  Handle = object
    p: ptr Payload

proc freePayload(p: ptr Payload) =
  freeCalls.inc()
  dealloc(p)

proc makeHandle(value: int): Handle =
  result.p = create(Payload)
  result.p.rc = 1
  result.p.value = value

proc `=destroy`*(x: Handle) =
  if x.p != nil:
    dec x.p.rc
    if x.p.rc == 0:
      freePayload(x.p)

proc `=wasMoved`*(x: var Handle) =
  x.p = nil

template share(dest, src) =
  if src.p != nil:
    inc src.p.rc
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
    doAssert a.p.rc == 1

    var b = `=dup`(a)
    doAssert b.p == a.p
    doAssert a.p.rc == 2

    `=destroy`(b)
    `=wasMoved`(b)
    doAssert a.p.rc == 1

    `=destroy`(a)
    `=wasMoved`(a)
    doAssert freeCalls == 1

  block:
    freeCalls = 0
    var a = makeHandle(11)
    var b = a
    doAssert a.p == b.p
    doAssert a.p.rc == 2

    a = b
    doAssert a.p == b.p
    doAssert a.p.rc == 2
    doAssert a.p.value == 11

    `=destroy`(a)
    `=wasMoved`(a)
    doAssert b.p.rc == 1
    doAssert freeCalls == 0

    `=destroy`(b)
    `=wasMoved`(b)
    doAssert freeCalls == 1

  echo "C36/C37/C38/C40: PASS"

main()
