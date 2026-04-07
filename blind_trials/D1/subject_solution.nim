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
    s.p = cast[ptr StrPayload](alloc(sizeof(int) * 2 + data.len))
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
  if s.p.counter > 1:
    # CoW detach: allocate new payload
    let newP = cast[ptr StrPayload](alloc(sizeof(int) * 2 + s.len))
    newP.cap = s.len
    newP.counter = 1
    for j in 0..<s.len:
      newP.data[j] = s.p.data[j]
    dec s.p.counter
    s.p = newP
  s.p.data[i] = c
