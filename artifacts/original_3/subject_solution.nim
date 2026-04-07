type
  StrPayload* = object
    cap*, counter*: int
    data*: UncheckedArray[char]
  String* = object
    len*: int
    p*: ptr StrPayload

proc initString*(s: var String; data: string) =
  let totalSize = sizeof(StrPayload) + data.len * sizeof(char)
  s.p = cast[ptr StrPayload](alloc0(totalSize))
  s.p.cap = data.len
  s.p.counter = 1
  s.len = data.len
  for i in 0 ..< data.len:
    s.p.data[i] = data[i]

proc getStr*(s: String): string =
  if s.p == nil: return ""
  result = newString(s.len)
  for i in 0 ..< s.len:
    result[i] = s.p.data[i]

proc mutateAt*(s: var String; i: int; c: char) =
  if i < 0 or i >= s.len: return
  if s.p.counter > 1:
    dec s.p.counter
    let oldP = s.p
    let totalSize = sizeof(StrPayload) + oldP.cap * sizeof(char)
    s.p = cast[ptr StrPayload](alloc0(totalSize))
    s.p.cap = oldP.cap
    s.p.counter = 1
    for j in 0 ..< s.len:
      s.p.data[j] = oldP.data[j]
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
  if a.p == b.p: return
  `=destroy`(a)
  `=wasMoved`(a)
  a.p = b.p
  a.len = b.len
  if b.p != nil:
    inc b.p.counter
