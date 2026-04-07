type
  StrPayload* = object
    cap*, counter*: int
    data*: UncheckedArray[char]

  String* = object
    len*: int
    p*: ptr StrPayload

proc initString*(s: var String; data: string) =
  let cap = max(data.len, 1)
  s.len = data.len
  s.p = cast[ptr StrPayload](alloc(sizeof(int) * 2 + cap))
  s.p.cap = cap
  s.p.counter = 1
  copyMem(addr s.p.data[0], unsafeAddr data[0], data.len)

proc getStr*(s: String): string =
  result = newString(s.len)
  copyMem(addr result[0], addr s.p.data[0], s.len)

proc mutateAt*(s: var String; i: int; c: char) =
  if s.p.counter > 1:
    # detach (CoW): allocate new payload
    let newP = cast[ptr StrPayload](alloc(sizeof(int) * 2 + s.p.cap))
    newP.cap = s.p.cap
    newP.counter = 1
    copyMem(addr newP.data[0], addr s.p.data[0], s.len)
    dec s.p.counter
    s.p = newP
  s.p.data[i] = c

proc `=destroy`*(x: var String) =
  if x.p != nil:
    dec x.p.counter
    if x.p.counter == 0:
      dealloc(x.p)
    x.p = nil

proc `=wasMoved`*(x: var String) =
  x.p = nil

proc `=dup`*(b: String): String {.nodestroy.} =
  result = String(len: b.len, p: b.p)
  if b.p != nil:
    inc b.p.counter

proc `=copy`*(a: var String; b: String) =
  if a.p == b.p:
    return
  `=destroy`(a)
  `=wasMoved`(a)
  a.len = b.len
  a.p = b.p
  if b.p != nil:
    inc b.p.counter
