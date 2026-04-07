type
  StrPayload* = object
    cap*, counter*: int
    data*: UncheckedArray[char]

  String* = object
    len*: int
    p*: ptr StrPayload

proc `=destroy`*(x: String) =
  if x.p != nil:
    dec x.p.counter
    if x.p.counter == 0:
      dealloc(x.p)

proc `=wasMoved`*(x: var String) =
  x.p = nil

proc `=dup`*(b: String): String {.nodestroy.} =
  result = String(len: b.len, p: b.p)
  if result.p != nil:
    inc result.p.counter

proc `=copy`*(a: var String; b: String) =
  if a.p == b.p:
    return
  `=destroy`(a)
  `=wasMoved`(a)
  a.len = b.len
  a.p = b.p
  if a.p != nil:
    inc a.p.counter

proc initString*(s: var String; data: string) =
  s.len = data.len
  if data.len == 0:
    s.p = nil
  else:
    s.p = cast[ptr StrPayload](alloc(sizeof(int) * 2 + data.len))
    s.p.cap = data.len
    s.p.counter = 1
    copyMem(addr s.p.data[0], unsafeAddr data[0], data.len)

proc getStr*(s: String): string =
  if s.p == nil:
    result = ""
  else:
    result = newString(s.len)
    copyMem(addr result[0], addr s.p.data[0], s.len)

proc mutateAt*(s: var String; i: int; c: char) =
  if s.p == nil:
    return
  if s.p.counter > 1:
    let oldP = s.p
    let oldLen = s.len
    s.p = cast[ptr StrPayload](alloc(sizeof(int) * 2 + oldLen))
    s.p.cap = oldLen
    s.p.counter = 1
    copyMem(addr s.p.data[0], addr oldP.data[0], oldLen)
    dec oldP.counter
    if oldP.counter == 0:
      dealloc(oldP)
  s.p.data[i] = c

when isMainModule:
  block:
    var s: String
    initString(s, "hello")
    assert s.getStr == "hello"

    var s2 = s
    assert s2.getStr == "hello"
    assert s.p.counter == 2

    s2.mutateAt(0, 'H')
    assert s2.getStr == "Hello"
    assert s.getStr == "hello"
    assert s.p.counter == 1
    assert s2.p.counter == 1

    var s3: String
    initString(s3, "")
    assert s3.getStr == ""

    var s4 = s3
    assert s4.getStr == ""

    var s5: String
    initString(s5, "test self-assign")
    s5 = s5
    assert s5.getStr == "test self-assign"

    echo "All tests passed!"
