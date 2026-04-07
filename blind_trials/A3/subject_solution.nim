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
  `=destroy`(s)
  `=wasMoved`(s)
  if data.len == 0:
    s.len = 0
    s.p = nil
  else:
    s.len = data.len
    let needed = sizeof(int) * 2 + data.len
    s.p = cast[ptr StrPayload](alloc(needed))
    s.p.cap = data.len
    s.p.counter = 1
    copyMem(addr s.p.data[0], unsafeAddr data[0], data.len)

proc getStr*(s: String): string =
  if s.p == nil or s.len == 0:
    result = ""
  else:
    result = newString(s.len)
    copyMem(addr result[0], addr s.p.data[0], s.len)

proc mutateAt*(s: var String; i: int; c: char) =
  if s.p == nil:
    return
  if s.p.counter > 1:
    # CoW: detach before mutating
    let oldP = s.p
    let needed = sizeof(int) * 2 + s.len
    s.p = cast[ptr StrPayload](alloc(needed))
    s.p.cap = s.len
    s.p.counter = 1
    copyMem(addr s.p.data[0], addr oldP.data[0], s.len)
    dec oldP.counter
  s.p.data[i] = c
