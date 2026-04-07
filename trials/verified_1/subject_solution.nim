type
  StrPayload* = object
    cap*: int
    counter*: int
    data*: UncheckedArray[char]

  String* = object
    len*: int
    p*: ptr StrPayload

proc initString*(s: var String; data: string) =
  let cap = data.len
  s.len = data.len
  let size = sizeof(StrPayload) + cap
  s.p = cast[ptr StrPayload](alloc(size))
  s.p.cap = cap
  s.p.counter = 1
  if cap > 0:
    copyMem(addr s.p.data[0], unsafeAddr data[0], cap)

proc getStr*(s: String): string =
  result = newString(s.len)
  if s.len > 0:
    copyMem(addr result[0], addr s.p.data[0], s.len)

proc mutateAt*(s: var String; i: int; c: char) =
  if s.p.counter > 1:
    let oldP = s.p
    let cap = oldP.cap
    let size = sizeof(StrPayload) + cap
    let newP = cast[ptr StrPayload](alloc(size))
    newP.cap = cap
    newP.counter = 1
    if s.len > 0:
      copyMem(addr newP.data[0], addr oldP.data[0], s.len)
    s.p = newP
    dec oldP.counter
  s.p.data[i] = c

proc `=destroy`*(x: String) =
  if x.p != nil:
    dec x.p.counter
    if x.p.counter <= 0:
      dealloc(x.p)

proc `=wasMoved`*(x: var String) =
  x.p = nil
  x.len = 0

proc `=dup`*(b: String): String {.nodestroy.} =
  result.len = b.len
  result.p = b.p
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
