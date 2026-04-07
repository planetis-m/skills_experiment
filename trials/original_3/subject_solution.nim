
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
  s.len = cap
  s.p = cast[ptr StrPayload](alloc(sizeof(int) * 2 + cap))
  s.p.cap = cap
  s.p.counter = 1
  copyMem(addr s.p.data, unsafeAddr data[0], cap)

proc getStr*(s: String): string =
  result = newString(s.len)
  if s.len > 0:
    copyMem(addr result[0], addr s.p.data, s.len)

proc mutateAt*(s: var String; i: int; c: char) =
  if s.p.counter > 1:
    # detach: allocate a new payload, copy data, dec old counter
    let cap = s.p.cap
    let newP = cast[ptr StrPayload](alloc(sizeof(int) * 2 + cap))
    newP.cap = cap
    newP.counter = 1
    copyMem(addr newP.data, addr s.p.data, s.len)
    dec s.p.counter
    s.p = newP
  s.p.data[i] = c

proc `=destroy`*(x: String) =
  if x.p != nil:
    dec x.p.counter
    if x.p.counter == 0:
      dealloc(x.p)

proc `=wasMoved`*(x: var String) =
  x.p = nil
  x.len = 0

proc `=dup`*(b: String): String {.nodestroy.} =
  result.p = b.p
  result.len = b.len
  if b.p != nil:
    inc b.p.counter

proc `=copy`*(a: var String; b: String) =
  if a.p == b.p:
    return
  `=destroy`(a)
  `=wasMoved`(a)
  a.p = b.p
  a.len = b.len
  if b.p != nil:
    inc b.p.counter
