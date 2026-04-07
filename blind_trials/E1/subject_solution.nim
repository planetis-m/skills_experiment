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
# Internal helpers (templates before hooks, as per Nim ownership rules)
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
else:
  template shortLen(s: String): int =
    int(s.short.len)

  template setShortLen(s: String; n: int) =
    s.short.len = int8(n)

when cpuEndian == littleEndian:
  template longCap(s: String): int =
    s.cap shr 1

  template setLongCap(s: String; n: int) =
    s.cap = (n shl 1) or strLongFlag
else:
  template longCap(s: String): int =
    s.cap and (not strLongFlag)

  template setLongCap(s: String; n: int) =
    s.cap = n or strLongFlag

template frees(s: String) =
  if isLong(s) and s.p != nil:
    dealloc(s.p)

# ---------------------------------------------------------------------------
# Ownership hooks — declared before any procs that use String
# ---------------------------------------------------------------------------

proc `=destroy`*(x: String) =
  frees(x)

proc `=wasMoved`*(x: var String) =
  x.cap = 0

proc `=dup`*(b: String): String =
  if isLong(b):
    if b.p != nil:
      let cap = longCap(b)
      result.p = cast[ptr UncheckedArray[char]](alloc(cap))
      copyMem(result.p, b.p, b.len + 1)
      result.len = b.len
      setLongCap(result, cap)
    else:
      result = String.default
  else:
    # Short string: bitwise copy of entire object
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
  let n = str.len
  if n > strMinCap:
    # Long string: allocate heap buffer
    let cap = max(n + 1, 8)
    result.p = cast[ptr UncheckedArray[char]](alloc(cap))
    copyMem(result.p, cast[pointer](unsafeAddr str[0]), n)
    result.p[n] = '\0'
    result.len = n
    setLongCap(result, cap)
  else:
    # Short string: store inline
    result = String.default
    setShortLen(result, n)
    if n > 0:
      copyMem(addr result.short.data[0], cast[pointer](unsafeAddr str[0]), n)
    result.short.data[n] = '\0'

proc getStr*(s: String): string =
  let n = len(s)
  if n == 0:
    result = ""
  else:
    result = newString(n)
    copyMem(addr result[0], data(s), n)

proc add*(s: var String; c: char) =
  let oldLen = len(s)
  let newLen = oldLen + 1

  if isLong(s):
    let cap = longCap(s)
    if newLen + 1 > cap:
      # Grow: allocate new buffer
      let newCap = max(newLen + 1, cap * 2)
      let newBuf = cast[ptr UncheckedArray[char]](alloc(newCap))
      if s.p != nil:
        copyMem(newBuf, s.p, oldLen)
        dealloc(s.p)
      newBuf[oldLen] = c
      newBuf[newLen] = '\0'
      s.p = newBuf
      s.len = newLen
      setLongCap(s, newCap)
    else:
      s.p[oldLen] = c
      s.p[newLen] = '\0'
      s.len = newLen
  else:
    if newLen <= strMinCap:
      # Still fits in short storage
      short(s).data[oldLen] = c
      short(s).data[newLen] = '\0'
      setShortLen(s, newLen)
    else:
      # Transition: short → long
      let newCap = max(newLen + 1, 8)
      let newBuf = cast[ptr UncheckedArray[char]](alloc(newCap))
      let d = data(s)
      if oldLen > 0:
        copyMem(newBuf, d, oldLen)
      newBuf[oldLen] = c
      newBuf[newLen] = '\0'
      `=destroy`(s)
      `=wasMoved`(s)
      s.p = newBuf
      s.len = newLen
      setLongCap(s, newCap)

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

when isMainModule:
  # Basic short string
  var s1 = toStr("hello")
  assert s1.len == 5
  assert getStr(s1) == "hello"

  # Empty string
  var s2 = toStr("")
  assert s2.len == 0
  assert getStr(s2) == ""

  # Long string
  var longInput = "abcdefghijklmnopqrstuvwxyz0123456789"
  var s3 = toStr(longInput)
  assert s3.len == longInput.len
  assert getStr(s3) == longInput

  # add on short string
  var s4 = toStr("abc")
  s4.add('d')
  assert getStr(s4) == "abcd"
  assert s4.len == 4

  # add transitioning from short to long
  var s5 = toStr("")
  for i in 0..<30:
    s5.add(char('a'.ord + (i mod 26)))
  assert s5.len == 30
  assert isLong(s5)

  # dup
  var s6 = toStr("world")
  var s7 = dup(s6)
  assert getStr(s7) == "world"
  s7.add('!')
  assert getStr(s6) == "world"  # original unchanged

  # dup long
  var s8 = dup(s3)
  assert getStr(s8) == longInput

  # copy (assignment)
  var s9: String
  s9 = s6
  assert getStr(s9) == "world"

  # self-assignment
  s9 = s9
  assert getStr(s9) == "world"

  # copy long over long
  var s10 = toStr("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")  # long
  var s11 = toStr("bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")  # long
  s10 = s11
  assert getStr(s10) == getStr(s11)

  # copy short over long
  var s12 = toStr("cccccccccccccccccccccccccccccccc")  # long
  var s13 = toStr("hi")  # short
  s12 = s13
  assert getStr(s12) == "hi"

  # copy long over short
  var s14 = toStr("short")
  var s15 = toStr("dddddddddddddddddddddddddddddddd")  # long
  s14 = s15
  assert getStr(s14) == getStr(s15)

  echo "All tests passed!"
