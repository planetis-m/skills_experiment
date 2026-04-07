import std/assertions
import subject_solution

var passCount = 0
var failCount = 0

template check(name: string; cond: bool; msg: string = "") =
  if cond:
    passCount.inc()
  else:
    failCount.inc()
    echo "  [FAIL] ", name, " — ", msg

proc testRepeatedAllocDealloc() =
  for round in 0 ..< 1000:
    var s: String
    initString(s, "test" & $round)
    var copy = s
    discard getStr(copy)
    mutateAt(copy, 0, 'X')
    discard getStr(s)
    discard getStr(copy)

proc testSelfAliasing() =
  var s: String
  initString(s, "hello")
  let pBefore = s.p
  let cBefore = s.p.counter
  `=copy`(s, s)
  check("self-alias pointer", s.p == pBefore, "pointer changed")
  check("self-alias counter", s.p.counter == cBefore, "counter changed")
  check("self-alias data", getStr(s) == "hello", "got " & getStr(s))

proc testMutationAfterMove() =
  var a: String
  initString(a, "test")
  var b = move(a)
  check("moved-from is nil", a.p == nil, "source not nil after move")
  check("moved-to valid", b.p != nil, "dest nil after move")
  check("moved-to data", getStr(b) == "test", "got " & getStr(b))
  # Mutation on moved-from should be no-op (p is nil)
  mutateAt(a, 0, 'X')

proc testDeepCopyChain() =
  var a: String
  initString(a, "abc")
  var b = a
  var c = b
  check("chain counter", a.p.counter == 3, "got " & $a.p.counter)
  mutateAt(c, 0, 'X')
  check("a unchanged", getStr(a) == "abc", "got " & getStr(a))
  check("b unchanged", getStr(b) == "abc", "got " & getStr(b))
  check("c mutated", getStr(c) == "Xbc", "got " & getStr(c))
  check("a counter 2", a.p.counter == 2, "got " & $a.p.counter)  # a and b share
  check("c counter 1", c.p.counter == 1, "got " & $c.p.counter)

proc testCounterAccuracy() =
  var base: String
  initString(base, "count")
  # Use a seq so compiler handles destruction
  var copies = newSeq[String](100)
  for i in 0 ..< 100:
    copies[i] = base
  check("100 copies counter", base.p.counter == 101, "got " & $base.p.counter)
  # Drop 99 by truncating the seq
  copies.setLen(1)
  check("after 99 destroys counter", base.p.counter == 2, "got " & $base.p.counter)

proc testEmptyString() =
  var s: String
  initString(s, "")
  check("empty len", s.len == 0, "got " & $s.len)
  check("empty getStr", getStr(s) == "", "got \"" & getStr(s) & "\"")
  check("empty counter", s.p.counter == 1, "got " & $s.p.counter)

proc main() =
  testRepeatedAllocDealloc()
  testSelfAliasing()
  testMutationAfterMove()
  testDeepCopyChain()
  testCounterAccuracy()
  testEmptyString()

  if failCount == 0:
    echo "ALL STRESS TESTS PASSED"
    quit(0)
  else:
    echo "TESTS FAILED: ", failCount, " failures, ", passCount, " passes"
    quit(1)

main()
