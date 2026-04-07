## SSO (Small String Optimization) String type for Nim with ORC.

when cpuEndian == littleEndian:
  const strLongFlag = 1
else:
  const strLongFlag = low(int)

type
  String* = object
    cap*: int
    longLen*: int        ## length when in long mode
    p*: ptr UncheckedArray[char]

const
  strMinCap = max(2, sizeof(String) - 1) - 1

type
  ShortString = object
    slen: int8
    data: array[strMinCap + 1, char]

static:
  assert sizeof(ShortString) == sizeof(String)

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

template isLong(s: String): bool =
  (s.cap and strLongFlag) == strLongFlag

template short(s: String): ptr ShortString =
  cast[ptr ShortString](addr s)

template rawData(s: String): ptr UncheckedArray[char] =
  if isLong(s): s.p
  else: cast[ptr UncheckedArray[char]](addr short(s).data[0])

when cpuEndian == littleEndian:

  template shortLen(s: String): int =
    int(short(s).slen shr 1)

  template setShortLen(s: String; n: int) =
    short(s).slen = int8(n shl 1)

  template longCap(s: String): int =
    s.cap shr 1

  template setLongCap(s: String; n: int) =
    s.cap = (n shl 1) or strLongFlag

else:

  template shortLen(s: String): int =
    int(short(s).slen)

  template setShortLen(s: String; n: int) =
    short(s).slen = int8(n)

  template longCap(s: String): int =
    s.cap and (not strLongFlag)

  template setLongCap(s: String; n: int) =
    s.cap = n or strLongFlag

template frees(s: String) =
  if isLong(s) and s.p != nil:
    when compileOption("threads"):
      deallocShared(s.p)
    else:
      dealloc(s.p)

# ---------------------------------------------------------------------------
# Ownership hooks  (declared before any proc that uses String)
# ---------------------------------------------------------------------------

proc `=destroy`*(x: String) =
  frees(x)

proc `=wasMoved`*(x: var String) =
  x.cap = 0

proc `=dup`*(b: String): String =
  if isLong(b):
    if b.p != nil and b.longLen > 0:
      when compileOption("threads"):
        result.p = cast[ptr UncheckedArray[char]](allocShared(b.longLen + 1))
      else:
        result.p = cast[ptr UncheckedArray[char]](alloc(b.longLen + 1))
      copyMem(result.p, b.p, b.longLen + 1)
    else:
      result.p = nil
    result.longLen = b.longLen
    setLongCap(result, b.longCap)
  else:
    copyMem(addr result, addr b, sizeof(String))

proc `=copy`*(a: var String; b: String) =
  if isLong(a) and isLong(b) and a.p == b.p:
    return
  `=destroy`(a)
  `=wasMoved`(a)
  if isLong(b):
    if b.p != nil and b.longLen > 0:
      when compileOption("threads"):
        a.p = cast[ptr UncheckedArray[char]](allocShared(b.longLen + 1))
      else:
        a.p = cast[ptr UncheckedArray[char]](alloc(b.longLen + 1))
      copyMem(a.p, b.p, b.longLen + 1)
    else:
      a.p = nil
    a.longLen = b.longLen
    setLongCap(a, b.longCap)
  else:
    copyMem(addr a, addr b, sizeof(String))

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

proc len*(s: String): int =
  if isLong(s): s.longLen
  else: shortLen(s)

proc toStr*(str: string): String =
  if str.len > strMinCap:
    result.longLen = str.len
    when compileOption("threads"):
      result.p = cast[ptr UncheckedArray[char]](allocShared(str.len + 1))
    else:
      result.p = cast[ptr UncheckedArray[char]](alloc(str.len + 1))
    copyMem(result.p, str[0].unsafeAddr, str.len + 1)
    setLongCap(result, str.len)
  else:
    result = default(String)
    setShortLen(result, str.len)
    if str.len > 0:
      copyMem(addr short(result).data[0], str[0].unsafeAddr, str.len)
    short(result).data[str.len] = '\0'

proc getStr*(s: String): string =
  let n = len(s)
  if n == 0:
    result = ""
  else:
    result = newString(n)
    copyMem(result[0].addr, rawData(s), n)

proc add*(s: var String; c: char) =
  if isLong(s):
    if s.longLen >= longCap(s):
      let newCap = max(s.longLen + 1, longCap(s) * 2)
      when compileOption("threads"):
        let newBuf = cast[ptr UncheckedArray[char]](allocShared(newCap + 1))
      else:
        let newBuf = cast[ptr UncheckedArray[char]](alloc(newCap + 1))
      if s.p != nil and s.longLen > 0:
        copyMem(newBuf, s.p, s.longLen)
      when compileOption("threads"):
        deallocShared(s.p)
      else:
        dealloc(s.p)
      s.p = newBuf
      setLongCap(s, newCap)
    s.p[s.longLen] = c
    inc s.longLen
    s.p[s.longLen] = '\0'
  else:
    let sl = shortLen(s)
    if sl < strMinCap:
      short(s).data[sl] = c
      setShortLen(s, sl + 1)
      short(s).data[sl + 1] = '\0'
    else:
      let newLen = sl + 1
      when compileOption("threads"):
        let buf = cast[ptr UncheckedArray[char]](allocShared(newLen + 1))
      else:
        let buf = cast[ptr UncheckedArray[char]](alloc(newLen + 1))
      if sl > 0:
        copyMem(buf, addr short(s).data[0], sl)
      buf[sl] = c
      buf[newLen] = '\0'
      s.p = buf
      s.longLen = newLen
      setLongCap(s, newLen)

# ---------------------------------------------------------------------------
# Smoke tests
# ---------------------------------------------------------------------------

when isMainModule:
  block:
    var a = toStr("hello")
    assert len(a) == 5
    assert getStr(a) == "hello"

    var b = toStr("")
    assert len(b) == 0
    assert getStr(b) == ""

    var c = toStr("this is a much longer string that exceeds SSO")
    assert len(c) == "this is a much longer string that exceeds SSO".len
    assert getStr(c) == "this is a much longer string that exceeds SSO"

    var d = a
    assert getStr(d) == "hello"
    assert getStr(a) == "hello"

    a.add('!')
    assert getStr(a) == "hello!"

    var e = toStr("x")
    e.add('y')
    e.add('z')
    assert getStr(e) == "xyz"

    var f = toStr("short")
    for i in 0..30:
      f.add('a')
    assert len(f) == 5 + 31
    var longExpected = "short"
    for i in 0..30: longExpected.add('a')
    assert getStr(f) == longExpected

    echo "All tests passed."
