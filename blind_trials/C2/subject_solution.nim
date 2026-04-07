type
  StrPayload* = object
    cap*, counter*: int
    data*: UncheckedArray[char]

  String* = object
    len*: int
    p*: ptr StrPayload

# --- Ownership hooks (declared before any procs that use String) ---

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

# --- Public API ---

proc initString*(s: var String; data: string) =
  s.len = data.len
  if data.len == 0:
    s.p = nil
  else:
    s.p = cast[ptr StrPayload](alloc(sizeof(int) * 2 + data.len))
    s.p.cap = data.len
    s.p.counter = 1
    copyMem(addr s.p.data[0], unsafeAddr data[0], data.len)

proc getStr*(s: String): string =
  if s.p == nil:
    result = ""
  else:
    result = newString(s.len)
    copyMem(addr result[0], addr s.p.data[0], s.len)

proc mutateAt*(s: var String; i: int; c: char) =
  if s.p == nil:
    return
  if s.p.counter > 1:
    # CoW detach: allocate new payload, copy data, dec old counter
    let newP = cast[ptr StrPayload](alloc(sizeof(int) * 2 + s.len))
    newP.cap = s.len
    newP.counter = 1
    copyMem(addr newP.data[0], addr s.p.data[0], s.len)
    dec s.p.counter
    s.p = newP
  s.p.data[i] = c

# --- Minimal smoke test ---

when isMainModule:
  var a: String
  initString(a, "hello")
  echo getStr(a)

  var b = a
  echo getStr(b)

  mutateAt(b, 0, 'H')
  echo getStr(a)
  echo getStr(b)

  var c: String
  initString(c, "")
  echo "empty: '", getStr(c), "'"
