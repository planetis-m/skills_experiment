type
  StrPayload* = object
    cap*, counter*: int
    data*: UncheckedArray[char]

  String* = object
    len*: int
    p*: ptr StrPayload

proc initString*(s: var String; data: string) =
  s.len = data.len
  if data.len == 0:
    s.p = nil
    return
  let cap = data.len
  s.p = cast[ptr StrPayload](alloc(sizeof(int) * 2 + cap * sizeof(char)))
  s.p.cap = cap
  s.p.counter = 1
  copyMem(addr s.p.data[0], unsafeAddr data[0], cap * sizeof(char))

proc getStr*(s: String): string =
  if s.p == nil:
    return ""
  result = newString(s.len)
  copyMem(addr result[0], addr s.p.data[0], s.len * sizeof(char))

proc mutateAt*(s: var String; i: int; c: char) =
  if s.p == nil:
    return
  if s.p.counter > 1:
    # CoW: detach before mutating
    let oldLen = s.len
    let newP = cast[ptr StrPayload](alloc(sizeof(int) * 2 + oldLen * sizeof(char)))
    newP.cap = oldLen
    newP.counter = 1
    copyMem(addr newP.data[0], addr s.p.data[0], oldLen * sizeof(char))
    dec s.p.counter
    s.p = newP
  s.p.data[i] = c

proc `=destroy`*(x: String) =
  if x.p != nil:
    dec x.p.counter
    if x.p.counter == 0:
      dealloc(x.p)

proc `=wasMoved`*(x: var String) =
  x.len = 0
  x.p = nil

proc `=dup`*(b: String): String {.nodestroy.} =
  result.len = b.len
  result.p = b.p
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
