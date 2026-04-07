## SSO (Small String Optimization) String type for Nim/ORC

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
# Ownership hooks  (declared before any procs that use String)
# ---------------------------------------------------------------------------

proc `=destroy`*(x: String) =
  frees(x)

proc `=wasMoved`*(x: var String) =
  x.cap = 0

proc `=dup`*(b: String): String =
  if b.isLong:
    result.len = b.len
    result.cap = b.cap
    if b.p != nil and b.len > 0:
      let c = b.longCap
      result.p = cast[ptr UncheckedArray[char]](alloc(c))
      copyMem(result.p, b.p, b.len + 1)
    else:
      result.p = nil
  else:
    # short string: copy entire object
    copyMem(addr result, addr b, sizeof(String))

proc `=copy`*(a: var String; b: String) =
  # self-assignment guard (long+long same pointer)
  if a.isLong and b.isLong and a.p == b.p:
    return
  `=destroy`(a)
  `=wasMoved`(a)
  if b.isLong:
    a.len = b.len
    a.cap = b.cap
    if b.p != nil and b.len > 0:
      let c = b.longCap
      a.p = cast[ptr UncheckedArray[char]](alloc(c))
      copyMem(a.p, b.p, b.len + 1)
    else:
      a.p = nil
  else:
    copyMem(addr a, addr b, sizeof(String))

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

proc len*(s: String): int {.inline.} =
  if s.isLong: s.len
  else: s.shortLen

proc toStr*(str: string): String =
  if str.len > strMinCap:
    # long string
    var cap = str.len
    result.cap = 0
    result.setLongCap(cap)
    result.len = str.len
    if str.len > 0:
      result.p = cast[ptr UncheckedArray[char]](alloc(cap))
      copyMem(result.p, str[0].unsafeAddr, str.len)
    else:
      result.p = nil
    # null terminate
    if result.p != nil:
      result.p[str.len] = '\0'
  else:
    # short string
    result.cap = 0
    result.setShortLen(str.len)
    if str.len > 0:
      copyMem(addr result.short.data[0], str[0].unsafeAddr, str.len)
    result.short.data[str.len] = '\0'

proc getStr*(s: String): string =
  let n = len(s)
  if n > 0:
    result = newString(n)
    copyMem(addr result[0], s.data, n)
  else:
    result = ""

proc add*(s: var String; c: char) =
  let oldLen = len(s)
  if s.isLong:
    # already on heap
    if oldLen + 1 <= s.longCap:
      # fits in current allocation
      s.p[oldLen] = c
      s.p[oldLen + 1] = '\0'
      s.len = oldLen + 1
    else:
      # grow
      var newCap = max(s.longCap * 2, oldLen + 1)
      let newBuf = cast[ptr UncheckedArray[char]](alloc(newCap))
      if s.p != nil:
        copyMem(newBuf, s.p, oldLen)
      newBuf[oldLen] = c
      newBuf[oldLen + 1] = '\0'
      if s.p != nil:
        dealloc(s.p)
      s.p = newBuf
      s.len = oldLen + 1
      s.setLongCap(newCap)
  else:
    if oldLen + 1 <= strMinCap:
      # still fits in short storage
      s.short.data[oldLen] = c
      s.short.data[oldLen + 1] = '\0'
      s.setShortLen(oldLen + 1)
    else:
      # transition to long
      var newCap = max(strMinCap * 2, oldLen + 1)
      let newBuf = cast[ptr UncheckedArray[char]](alloc(newCap))
      copyMem(newBuf, addr s.short.data[0], oldLen)
      newBuf[oldLen] = c
      newBuf[oldLen + 1] = '\0'
      # reset to clean state before setting long fields
      s.cap = 0
      s.setLongCap(newCap)
      s.len = oldLen + 1
      s.p = newBuf

# ---------------------------------------------------------------------------
# Basic smoke test (compiled away unless run)
# ---------------------------------------------------------------------------

when isMainModule:
  block:
    var a = toStr("hello")
    assert len(a) == 5
    assert a.getStr == "hello"

    var b = toStr("")
    assert len(b) == 0
    assert b.getStr == ""

    # short string add
    var c = toStr("ab")
    c.add('c')
    assert c.getStr == "abc"

    # transition short → long
    var d = toStr("")
    let longStr = "this is a much longer string that exceeds SSO"
    for ch in longStr:
      d.add(ch)
    assert d.getStr == longStr

    # copy
    var e = toStr("world")
    var f = e
    assert f.getStr == "world"
    assert len(f) == 5

    # copy long
    var g = toStr("a reasonably long string for heap allocation")
    var h = g
    assert h.getStr == g.getStr

    # self-assignment
    var i = toStr("self")
    i = i
    assert i.getStr == "self"

    echo "All tests passed."
