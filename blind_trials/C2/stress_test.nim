import std/assertions
import subject_solution

var passCount = 0
var failCount = 0
template check(name: string; cond: bool; msg: string = "") =
  if cond: passCount.inc()
  else: failCount.inc(); echo "  [FAIL] ", name, " — ", msg

proc testRefCount() =
  var a: String
  initString(a, "hello")
  check("init counter=1", a.p.counter == 1, "got " & $a.p.counter)
  var b = a
  check("copy counter=2", a.p.counter == 2, "got " & $a.p.counter)
  check("shared payload", a.p == b.p)

proc testCow() =
  var a: String
  initString(a, "hello")
  var b = a
  mutateAt(b, 0, 'H')
  check("detached", a.p != b.p, "still sharing")
  check("original", getStr(a) == "hello", "got " & getStr(a))
  check("mutated", getStr(b) == "Hello", "got " & getStr(b))

proc testSelfCopy() =
  var a: String
  initString(a, "self")
  `=copy`(a, a)
  check("self-copy data", getStr(a) == "self", "got " & getStr(a))

proc testMove() =
  var a: String
  initString(a, "test")
  var b = move(a)
  check("moved-from nil", a.p == nil)
  check("moved-to valid", b.p != nil)
  check("moved-to data", getStr(b) == "test")

proc testEmpty() =
  var a: String
  initString(a, "")
  check("empty str", getStr(a) == "", "got \"" & getStr(a) & "\"")

proc main() =
  testRefCount()
  testCow()
  testSelfCopy()
  testMove()
  testEmpty()
  if failCount == 0:
    echo "ALL STRESS TESTS PASSED"
    quit(0)
  else:
    echo "FAILED: ", failCount, " failures"
    quit(1)
main()
