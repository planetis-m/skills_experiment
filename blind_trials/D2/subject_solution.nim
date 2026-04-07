type
  StrPayload* = object
    cap*, counter*: int
    data*: UncheckedArray[char]

  String* = object
    len*: int
    p*: ptr StrPayload

# ── Hooks (declared before procs that use the type) ──

proc `=destroy`*(x: String) =
  if x.p != nil:
    dec x.p.counter
    if x.p.counter == 0:
      dealloc(x.p)

proc `=wasMoved`*(x: var String) =
  x.p = nil

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

# ── Public API ──

proc initString*(s: var String; data: string) =
  `=destroy`(s)
  `=wasMoved`(s)
  s.len = data.len
  if data.len > 0:
    s.p = cast[ptr StrPayload](alloc(sizeof(int) * 2 + data.len))
    s.p.cap = data.len
    s.p.counter = 1
    copyMem(addr s.p.data, unsafeAddr data[0], data.len)
  else:
    s.p = nil

proc getStr*(s: String): string =
  if s.p != nil and s.len > 0:
    result = newString(s.len)
    copyMem(addr result[0], addr s.p.data, s.len)
  else:
    result = ""

proc mutateAt*(s: var String; i: int; c: char) =
  if s.p.counter > 1:
    # CoW detach: allocate new payload, copy data, dec old counter
    let oldP = s.p
    let oldLen = s.len
    s.p = cast[ptr StrPayload](alloc(sizeof(int) * 2 + oldLen))
    s.p.cap = oldLen
    s.p.counter = 1
    copyMem(addr s.p.data, addr oldP.data, oldLen)
    dec oldP.counter
    # oldP will be freed when its last owner destroys
  s.p.data[i] = c
