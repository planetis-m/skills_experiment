## SSO (Small String Optimization) String type for Nim with ORC ownership hooks.

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

template dataPtr*(s: String): ptr UncheckedArray[char] =
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
    when compileOption("threads"):
      deallocShared(s.p)
    else:
      dealloc(s.p)

template getLen*(s: String): int =
  if s.isLong: s.len
  else: s.shortLen

# ---------------------------------------------------------------------------
# Ownership hooks (declared before any proc that uses String)
# ---------------------------------------------------------------------------

proc `=destroy`*(x: String) =
  frees(x)

proc `=wasMoved`*(x: var String) =
  x.cap = 0

proc `=dup`*(b: String): String =
  if b.isLong:
    let cap = b.longCap
    result.len = b.len
    setLongCap(result, cap)
    if b.p != nil and b.len > 0:
      when compileOption("threads"):
        result.p = cast[ptr UncheckedArray[char]](allocShared(cap + 1))
      else:
        result.p = cast[ptr UncheckedArray[char]](alloc(cap + 1))
      copyMem(result.p, b.p, b.len + 1)   # include null terminator
    else:
      result.p = nil
  else:
    # short string: copy entire object
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
    # long string: heap allocate
    var cap = str.len
    result.len = str.len
    setLongCap(result, cap)
    when compileOption("threads"):
      result.p = cast[ptr UncheckedArray[char]](allocShared(cap + 1))
    else:
      result.p = cast[ptr UncheckedArray[char]](alloc(cap + 1))
    copyMem(result.p, cast[ptr UncheckedArray[char]](unsafeAddr str[0]), str.len)
    result.p[str.len] = '\0'
  else:
    # short string: store inline
    result = default(String)
    setShortLen(result, str.len)
    if str.len > 0:
      copyMem(addr result.short.data[0], unsafeAddr str[0], str.len)
    result.short.data[str.len] = '\0'

proc getStr*(s: String): string =
  let l = s.getLen
  if l == 0:
    result = ""
  else:
    result = newString(l)
    copyMem(addr result[0], s.dataPtr, l)

proc add*(s: var String; c: char) =
  if s.isLong:
    # already on heap
    let cap = s.longCap
    if s.len < cap:
      s.p[s.len] = c
      inc s.len
      s.p[s.len] = '\0'
    else:
      # grow
      var newCap = cap * 2
      if newCap < cap + 1: newCap = cap + 1
      when compileOption("threads"):
        var newBuf = cast[ptr UncheckedArray[char]](allocShared(newCap + 1))
      else:
        var newBuf = cast[ptr UncheckedArray[char]](alloc(newCap + 1))
      if s.len > 0:
        copyMem(newBuf, s.p, s.len)
      newBuf[s.len] = c
      newBuf[s.len + 1] = '\0'
      frees(s)
      s.p = newBuf
      setLongCap(s, newCap)
      inc s.len
  else:
    # short string
    let sl = s.shortLen
    if sl < strMinCap:
      s.short.data[sl] = c
      setShortLen(s, sl + 1)
      s.short.data[sl + 1] = '\0'
    else:
      # transition to long
      var newCap = strMinCap * 2
      if newCap < sl + 1: newCap = sl + 1
      when compileOption("threads"):
        var newBuf = cast[ptr UncheckedArray[char]](allocShared(newCap + 1))
      else:
        var newBuf = cast[ptr UncheckedArray[char]](alloc(newCap + 1))
      if sl > 0:
        copyMem(newBuf, addr s.short.data[0], sl)
      newBuf[sl] = c
      newBuf[sl + 1] = '\0'
      # destroy old (short, so frees is a no-op) and assign
      `=destroy`(s)
      `=wasMoved`(s)
      s.p = newBuf
      s.len = sl + 1
      setLongCap(s, newCap)

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

when isMainModule:
  block: # basic short string
    var s = toStr("hello")
    assert len(s) == 5
    assert s.getStr == "hello"
    assert not s.isLong

  block: # empty string
    var s = toStr("")
    assert len(s) == 0
    assert s.getStr == ""
    assert not s.isLong

  block: # long string
    var longStr = "abcdefghijklmnopqrstuvwxyz"
    var s = toStr(longStr)
    assert len(s) == longStr.len
    assert s.getStr == longStr
    assert s.isLong

  block: # dup short
    var s = toStr("world")
    var s2 = s
    assert s2.getStr == "world"

  block: # dup long
    var s = toStr("abcdefghijklmnopqrstuvwxyz")
    var s2 = s
    assert s2.getStr == "abcdefghijklmnopqrstuvwxyz"

  block: # add short stays short
    var s = toStr("ab")
    s.add('c')
    assert s.getStr == "abc"
    assert not s.isLong

  block: # add triggers short-to-long
    var s = toStr("")
    for i in 0..<strMinCap:
      s.add(char('a'.ord + i))
    assert len(s) == strMinCap
    assert not s.isLong
    s.add('z')
    assert s.isLong
    let expected = "abcdefghijklmnopqrstuvwxyz"[0 ..< strMinCap] & "z"
    assert s.getStr == expected

  block: # copy long to long
    var a = toStr("abcdefghijklmnopqrstuvwxyz")
    var b = toStr("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    b = a
    assert b.getStr == "abcdefghijklmnopqrstuvwxyz"

  block: # copy short to long
    var a = toStr("hi")
    var b = toStr("abcdefghijklmnopqrstuvwxyz")
    b = a
    assert b.getStr == "hi"
    assert not b.isLong

  block: # copy long to short
    var a = toStr("abcdefghijklmnopqrstuvwxyz")
    var b = toStr("hi")
    b = a
    assert b.getStr == "abcdefghijklmnopqrstuvwxyz"
    assert b.isLong

  block: # self-assignment long
    var a = toStr("abcdefghijklmnopqrstuvwxyz")
    a = a
    assert a.getStr == "abcdefghijklmnopqrstuvwxyz"

  block: # destroy after move
    var a = toStr("hello")
    var b = a
    assert b.getStr == "hello"

  echo "All tests passed!"
