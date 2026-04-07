## SSO (Small String Optimization) String type for Nim

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
# Internal helpers (templates / procs) — declared before hooks
# ---------------------------------------------------------------------------

template isLong*(s: String): bool =
  (s.cap and strLongFlag) == strLongFlag

template short*(s: String): ptr ShortString =
  cast[ptr ShortString](addr s)

template data*(s: String): ptr UncheckedArray[char] =
  if s.isLong: s.p
  else: cast[ptr UncheckedArray[char]](addr s.short.data[0])

when cpuEndian == littleEndian:

  template shortLen*(s: String): int =
    int(s.short.len shr 1)

  template setShortLen*(s: String; n: int) =
    s.short.len = int8(n shl 1)

  template longCap*(s: String): int =
    s.cap shr 1

  template setLongCap*(s: String; n: int) =
    s.cap = (n shl 1) or strLongFlag

else:
  # Big-endian: flag lives in the sign bit of cap, no shifting needed
  template shortLen*(s: String): int =
    int(s.short.len)

  template setShortLen*(s: String; n: int) =
    s.short.len = int8(n)

  template longCap*(s: String): int =
    s.cap and (not strLongFlag)

  template setLongCap*(s: String; n: int) =
    s.cap = n or strLongFlag

template frees*(s: String) =
  if s.isLong and s.p != nil:
    dealloc(s.p)

# ---------------------------------------------------------------------------
# Ownership hooks
# ---------------------------------------------------------------------------

proc `=destroy`*(x: String) =
  frees(x)

proc `=wasMoved`*(x: var String) =
  x.cap = 0

proc `=dup`*(b: String): String =
  if b.isLong:
    if b.p != nil:
      let cap = b.longCap
      result.p = cast[ptr UncheckedArray[char]](alloc(cap * sizeof(char)))
      copyMem(result.p, b.p, b.len * sizeof(char))
      result.p[b.len] = '\0'
      result.len = b.len
      result.setLongCap(cap)
    else:
      result = default(String)
  else:
    # short string — bitwise copy of the entire object
    copyMem(addr result, addr b, sizeof(String))

proc `=copy`*(a: var String; b: String) =
  if a.isLong and b.isLong and a.p == b.p:
    return
  `=destroy`(a)
  `=wasMoved`(a)
  a = `=dup`(b)

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

proc len*(s: String): int =
  if s.isLong: s.len
  else: s.shortLen

proc toStr*(str: string): String =
  if str.len > strMinCap:
    # Long string: heap allocation
    result.len = str.len
    var cap = str.len
    result.setLongCap(cap)
    result.p = cast[ptr UncheckedArray[char]](alloc(cap * sizeof(char)))
    copyMem(result.p, str[0].unsafeAddr, str.len * sizeof(char))
    result.p[str.len] = '\0'
  else:
    # Short string: inline storage
    result.setShortLen(str.len)
    if str.len > 0:
      copyMem(addr result.short.data[0], str[0].unsafeAddr, str.len * sizeof(char))
    result.short.data[str.len] = '\0'

proc getStr*(s: String): string =
  let n = s.len
  if n == 0:
    result = ""
  else:
    result = newString(n)
    copyMem(addr result[0], s.data, n * sizeof(char))

proc add*(s: var String; c: char) =
  let oldLen = s.len
  if s.isLong:
    # Already on the heap — grow if needed
    let cap = s.longCap
    if oldLen + 1 >= cap:
      let newCap = max(cap * 2, oldLen + 2)
      let newBuf = cast[ptr UncheckedArray[char]](alloc(newCap * sizeof(char)))
      if s.p != nil:
        copyMem(newBuf, s.p, oldLen * sizeof(char))
        dealloc(s.p)
      s.p = newBuf
      s.setLongCap(newCap)
    s.p[oldLen] = c
    s.p[oldLen + 1] = '\0'
    s.len = oldLen + 1
  else:
    # Short string
    if oldLen + 1 <= strMinCap:
      # Still fits inline
      s.short.data[oldLen] = c
      s.short.data[oldLen + 1] = '\0'
      s.setShortLen(oldLen + 1)
    else:
      # Transition to long
      let newCap = max(strMinCap * 2, oldLen + 2)
      let newBuf = cast[ptr UncheckedArray[char]](alloc(newCap * sizeof(char)))
      copyMem(newBuf, addr s.short.data[0], oldLen * sizeof(char))
      newBuf[oldLen] = c
      newBuf[oldLen + 1] = '\0'
      `=destroy`(s)
      `=wasMoved`(s)
      s.p = newBuf
      s.len = oldLen + 1
      s.setLongCap(newCap)

# ---------------------------------------------------------------------------
# Smoke test
# ---------------------------------------------------------------------------

when isMainModule:
  block:
    var a = toStr("hello")
    assert a.len == 5
    assert a.getStr == "hello"

    var b = toStr("")
    assert b.len == 0
    assert b.getStr == ""

    var c = toStr("this is a longer string that exceeds SSO")
    assert c.len == "this is a longer string that exceeds SSO".len
    assert c.getStr == "this is a longer string that exceeds SSO"

    # dup
    var d = `=dup`(c)
    assert d.getStr == c.getStr

    # copy
    var e: String
    `=copy`(e, a)
    assert e.getStr == "hello"

    # add — short stays short
    var f = toStr("ab")
    f.add('c')
    assert f.getStr == "abc"
    assert not f.isLong

    # add — transition short → long
    var g = toStr("")
    for ch in "abcdefghijklmnopqrstuvwxyz":
      g.add(ch)
    assert g.getStr == "abcdefghijklmnopqrstuvwxyz"
    assert g.isLong

    # self-assignment
    `=copy`(a, a)
    assert a.getStr == "hello"

    echo "All tests passed."
