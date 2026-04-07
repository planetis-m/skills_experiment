## SSO (Small String Optimization) String type for Nim with ARC/ORC ownership hooks.

when cpuEndian == littleEndian:
  const strLongFlag = 1
else:
  const strLongFlag = low(int)

type
  String* = object
    cap, len: int
    p: ptr UncheckedArray[char]

const
  strMinCap = max(2, sizeof(String) - 1) - 1

type
  ShortString = object
    len: int8
    data: array[strMinCap + 1, char]

static: assert sizeof(ShortString) == sizeof(String)

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

template isLong(s: String): bool =
  (s.cap and strLongFlag) == strLongFlag

template short(s: String): ptr ShortString =
  cast[ptr ShortString](addr s)

template data(s: String): ptr UncheckedArray[char] =
  if isLong(s): s.p
  else: cast[ptr UncheckedArray[char]](addr s.short.data[0])

when cpuEndian == littleEndian:
  template shortLen(s: String): int =
    int(s.short.len shr 1)

  template setShortLen(s: String; n: int) =
    s.short.len = int8(n shl 1)

  template longCap(s: String): int =
    s.cap shr 1

  template setLongCap(s: var String; n: int) =
    s.cap = (n shl 1) or strLongFlag
else:
  template shortLen(s: String): int =
    int(s.short.len)

  template setShortLen(s: String; n: int) =
    s.short.len = int8(n)

  template longCap(s: String): int =
    s.cap and (not strLongFlag)

  template setLongCap(s: var String; n: int) =
    s.cap = n or strLongFlag

template frees(s: String) =
  if isLong(s) and s.p != nil:
    dealloc(s.p)

# ---------------------------------------------------------------------------
# Ownership hooks (declared before any proc using String)
# ---------------------------------------------------------------------------

proc `=destroy`*(x: String) =
  frees(x)

proc `=wasMoved`*(x: var String) =
  x.cap = 0

proc `=dup`*(b: String): String =
  if isLong(b):
    if b.p != nil:
      let cap = longCap(b)
      result.p = cast[ptr UncheckedArray[char]](alloc(cap * sizeof(char)))
      copyMem(result.p, b.p, b.len + 1)
      result.len = b.len
      setLongCap(result, cap)
    else:
      result = default(String)
  else:
    copyMem(addr result, addr b, sizeof(String))

proc `=copy`*(a: var String; b: String) =
  if isLong(a) and isLong(b) and a.p == b.p:
    return
  `=destroy`(a)
  `=wasMoved`(a)
  a = `=dup`(b)

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

proc len*(s: String): int =
  if isLong(s): s.len
  else: shortLen(s)

proc toStr*(str: string): String =
  if str.len > strMinCap:
    result.len = str.len
    let cap = str.len  # exact fit for now
    result.p = cast[ptr UncheckedArray[char]](alloc(cap * sizeof(char)))
    copyMem(result.p, unsafeAddr str[0], str.len + 1)
    setLongCap(result, cap)
  else:
    setShortLen(result, str.len)
    if str.len > 0:
      copyMem(addr result.short.data[0], unsafeAddr str[0], str.len)
    result.short.data[str.len] = '\0'

proc getStr*(s: String): string =
  let n = s.len
  result = newString(n)
  if n > 0:
    copyMem(addr result[0], s.data, n)

proc add*(s: var String; c: char) =
  let n = s.len
  if isLong(s):
    let cap = longCap(s)
    if n + 1 > cap:
      let newCap = max(cap * 2, n + 2)
      let newBuf = cast[ptr UncheckedArray[char]](alloc(newCap * sizeof(char)))
      if s.p != nil:
        copyMem(newBuf, s.p, n + 1)
        dealloc(s.p)
      s.p = newBuf
      setLongCap(s, newCap)
    s.p[n] = c
    s.p[n + 1] = '\0'
    s.len = n + 1
  else:
    if n + 1 <= strMinCap:
      s.short.data[n] = c
      s.short.data[n + 1] = '\0'
      setShortLen(s, n + 1)
    else:
      # Transition short -> long
      let newCap = max(strMinCap * 2, n + 2)
      let newBuf = cast[ptr UncheckedArray[char]](alloc(newCap * sizeof(char)))
      copyMem(newBuf, addr s.short.data[0], n)
      newBuf[n] = c
      newBuf[n + 1] = '\0'
      `=wasMoved`(s)
      s.p = newBuf
      s.len = n + 1
      setLongCap(s, newCap)

# ---------------------------------------------------------------------------
# Quick self-test
# ---------------------------------------------------------------------------

when isMainModule:
  block:
    var a = toStr("hello")
    assert a.len == 5
    assert a.getStr == "hello"

    var b = toStr("")
    assert b.len == 0
    assert b.getStr == ""

    # short string add
    var c = toStr("hi")
    c.add('!')
    assert c.getStr == "hi!"

    # short -> long transition
    var d = toStr("short")
    for ch in " string that exceeds the small buffer limit":
      d.add(ch)
    assert d.getStr == "short string that exceeds the small buffer limit"

    # dup
    var e = toStr("world")
    var f = `=dup`(e)
    assert f.getStr == "world"
    f.add('!')
    assert f.getStr == "world!"
    assert e.getStr == "world"  # independent

    # copy
    var g = toStr("a")
    var h = toStr("b")
    g = h
    assert g.getStr == "b"
    assert h.getStr == "b"

    # self-assignment
    var s = toStr("self")
    s = s
    assert s.getStr == "self"

    echo "All tests passed."
