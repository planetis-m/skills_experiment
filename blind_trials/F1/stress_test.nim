import std/assertions
import subject_solution

var passCount = 0
var failCount = 0
template check(name: string; cond: bool; msg: string = "") =
  if cond: passCount.inc()
  else: failCount.inc(); echo "  [FAIL] ", name, " — ", msg

proc testShortString() =
  var s = toStr("hi")
  check("short len", len(s) == 2, "got " & $len(s))
  check("short data", getStr(s) == "hi", "got \"" & getStr(s) & "\"")

proc testLongString() =
  var s = toStr("hello world, this is a long string that exceeds SSO limit")
  check("long len", len(s) == 57, "got " & $len(s))
  check("long data", getStr(s) == "hello world, this is a long string that exceeds SSO limit")

proc testEmpty() =
  var s = toStr("")
  check("empty len", len(s) == 0, "got " & $len(s))
  check("empty data", getStr(s) == "", "got \"" & getStr(s) & "\"")

proc testCopy() =
  var a = toStr("copy test string long enough")
  var b = a
  check("copy long data", getStr(b) == "copy test string long enough")
  # They should be independent copies
  check("copy long data b", getStr(b) == "copy test string long enough")

proc testCopyShort() =
  var a = toStr("short")
  var b = a
  check("copy short data", getStr(b) == "short")

proc testMove() =
  var a = toStr("move test string that is long for heap")
  let expected = getStr(a)
  var b = move(a)
  check("moved data", getStr(b) == expected)

proc testSelfCopy() =
  var a = toStr("self")
  `=copy`(a, a)
  check("self-copy short", getStr(a) == "self")
  var b = toStr("self assignment test with a long heap string")
  `=copy`(b, b)
  check("self-copy long", getStr(b) == "self assignment test with a long heap string")

proc testDup() =
  var a = toStr("dup test value that is long enough for heap storage")
  var b = `=dup`(a)
  check("dup data", getStr(b) == "dup test value that is long enough for heap storage")
  check("dup data b", getStr(b) == "dup test value that is long enough for heap storage")

proc testDupShort() =
  var a = toStr("short")
  var b = `=dup`(a)
  check("dup short data", getStr(b) == "short")

proc testAdd() =
  var s = toStr("ab")
  add(s, 'c')
  check("add short", getStr(s) == "abc")
  # Grow into long string
  var s2 = toStr("ab")
  for i in 0..30:
    add(s2, 'x')
  check("add grows to long", len(s2) == 33, "got " & $len(s2))

proc testAddEmpty() =
  var s = toStr("")
  add(s, 'a')
  check("add to empty", getStr(s) == "a")

proc testOverwrite() =
  var a = toStr("this is a long original string value")
  a = toStr("short")
  check("overwrite long with short", getStr(a) == "short")
  var b = toStr("tiny")
  b = toStr("now this is a much longer replacement string")
  check("overwrite short with long", getStr(b) == "now this is a much longer replacement string")

proc testManyStrings() =
  # Allocate and free many strings to test for memory issues
  for i in 0..100:
    var s = toStr("string number " & $i)
    discard getStr(s)

proc main() =
  testShortString()
  testLongString()
  testEmpty()
  testCopy()
  testCopyShort()
  testMove()
  testSelfCopy()
  testDup()
  testDupShort()
  testAdd()
  testAddEmpty()
  testOverwrite()
  testManyStrings()
  if failCount == 0:
    echo "ALL STRESS TESTS PASSED"
    quit(0)
  else:
    echo "FAILED: ", failCount, " failures"
    quit(1)
main()
