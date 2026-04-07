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
  let cap = max(data.len, 1)
  s.p = cast[ptr StrPayload](alloc(sizeof(int) * 2 + cap * sizeof(char)))
  s.p.cap = cap
  s.p.counter = 1
  s.len = data.len
  copyMem(addr s.p.data[0], unsafeAddr data[0], data.len)

proc getStr*(s: String): string =
  if s.p == nil or s.len == 0:
    result = ""
  else:
    result = newString(s.len)
    copyMem(addr result[0], addr s.p.data[0], s.len)

proc mutateAt*(s: var String; i: int; c: char) =
  if s.p.counter > 1:
    let oldP = s.p
    let oldLen = s.len
    let cap = max(oldLen, 1)
    s.p = cast[ptr StrPayload](alloc(sizeof(int) * 2 + cap * sizeof(char)))
    s.p.cap = cap
    s.p.counter = 1
    s.len = oldLen
    copyMem(addr s.p.data[0], addr oldP.data[0], oldLen)
    dec oldP.counter
  s.p.data[i] = c
