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
  check("long len", len(s) == 54, "got " & $len(s))
  check("long data", getStr(s) == "hello world, this is a long string that exceeds SSO limit")

proc testEmpty() =
  var s = toStr("")
  check("empty len", len(s) == 0, "got " & $len(s))
  check("empty data", getStr(s) == "", "got \"" & getStr(s) & "\"")

proc testCopy() =
  var a = toStr("copy test")
  var b = a
  check("copy data", getStr(b) == "copy test", "got \"" & getStr(b) & "\"")
  # Modify original shouldn't affect copy
  discard a

proc testMove() =
  var a = toStr("move test")
  var b = move(a)
  check("moved data", getStr(b) == "move test")
  # moved-from state: cap == 0
  check("moved-from cap", a.cap == 0, "got cap=" & $a.cap)

proc testSelfCopy() =
  var a = toStr("self")
  `=copy`(a, a)
  check("self-copy", getStr(a) == "self")

proc testDup() =
  var a = toStr("dup test value that is long enough for heap")
  var b = `=dup`(a)
  check("dup data", getStr(b) == "dup test value that is long enough for heap")
  check("dup independent", a.p != nil and b.p != nil and a.p != b.p, "should be independent heap allocations")

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

proc testDestroyShort() =
  block:
    var s = toStr("short")
    # goes out of scope, =destroy should not crash

proc testDestroyLong() =
  block:
    var s = toStr("this is definitely a long string on the heap")
    # goes out of scope, =destroy should free the pointer

proc testOverwrite() =
  var a = toStr("this is a long original string value")
  a = toStr("short")
  check("overwrite long with short", getStr(a) == "short")
  var b = toStr("tiny")
  b = toStr("now this is a much longer replacement string")
  check("overwrite short with long", getStr(b) == "now this is a much longer replacement string")

proc main() =
  testShortString()
  testLongString()
  testEmpty()
  testCopy()
  testMove()
  testSelfCopy()
  testDup()
  testDupShort()
  testAdd()
  testAddEmpty()
  testDestroyShort()
  testDestroyLong()
  testOverwrite()
  if failCount == 0:
    echo "ALL STRESS TESTS PASSED"
    quit(0)
  else:
    echo "FAILED: ", failCount, " failures"
    quit(1)
main()
