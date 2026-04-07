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
  s.p = cast[ptr StrPayload](alloc(sizeof(int) * 2 + cap * sizeof(char)))
  s.p.cap = cap
  s.p.counter = 1
  for i in 0..<data.len:
    s.p.data[i] = data[i]

proc getStr*(s: String): string =
  result = newString(s.len)
  for i in 0..<s.len:
    result[i] = s.p.data[i]

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

proc mutateAt*(s: var String; i: int; c: char) =
  if s.p.counter > 1:
    let oldP = s.p
    let cap = oldP.cap
    s.p = cast[ptr StrPayload](alloc(sizeof(int) * 2 + cap * sizeof(char)))
    s.p.cap = cap
    s.p.counter = 1
    for j in 0..<s.len:
      s.p.data[j] = oldP.data[j]
    dec oldP.counter
  s.p.data[i] = c
