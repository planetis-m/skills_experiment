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
  x.len = 0

proc `=dup`*(b: String): String {.nodestroy.} =
  result = String(len: b.len, p: b.p)
  if b.p != nil:
    inc b.p.counter

proc `=copy`*(a: var String; b: String) =
  if a.p == b.p: return
  `=destroy`(a)
  `=wasMoved`(a)
  a.len = b.len
  a.p = b.p
  if b.p != nil:
    inc b.p.counter

proc initString*(s: var String; data: string) =
  s.len = data.len
  if data.len > 0:
    s.p = cast[ptr StrPayload](alloc(sizeof(int) + sizeof(int) + data.len * sizeof(char)))
    s.p.cap = data.len
    s.p.counter = 1
    for i in 0..<data.len:
      s.p.data[i] = data[i]
  else:
    s.p = nil

proc getStr*(s: String): string =
  result = newString(s.len)
  if s.p != nil:
    for i in 0..<s.len:
      result[i] = s.p.data[i]

proc mutateAt*(s: var String; i: int; c: char) =
  if s.p != nil and s.p.counter > 1:
    let oldP = s.p
    let oldLen = s.len
    s.p = cast[ptr StrPayload](alloc(sizeof(int) + sizeof(int) + oldLen * sizeof(char)))
    s.p.cap = oldLen
    s.p.counter = 1
    for j in 0..<oldLen:
      s.p.data[j] = oldP.data[j]
    dec oldP.counter
    # oldP will eventually be deallocated by its last owner
  if s.p != nil:
    s.p.data[i] = c

# ---------------------------------------------------------------------------
# Minimal smoke test
# ---------------------------------------------------------------------------

when isMainModule:
  block:
    var a: String
    initString(a, "hello")
    assert a.len == 5
    assert getStr(a) == "hello"

    # dup shares payload
    var b = a
    assert b.len == 5
    assert b.p.counter == 2

    # CoW detach on mutate
    mutateAt(b, 0, 'H')
    assert b.p.counter == 1
    assert a.p.counter == 1
    assert getStr(a) == "hello"
    assert getStr(b) == "Hello"

    # copy
    var c: String
    c = a
    assert c.p.counter == 2
    assert getStr(c) == "hello"

    # empty string
    var e: String
    initString(e, "")
    assert e.len == 0
    assert e.p == nil
    assert getStr(e) == ""

    # self-copy
    c = c
    assert c.p.counter == 2

    echo "All tests passed."
