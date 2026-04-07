# validator.nim
# Validates a subject_solution.nim custom String type.
# This file provides a wrapper that adapts the subject's String type
# to a standard test interface, then runs correctness tests.
#
# Usage:
#   1. Copy subject_solution.nim (containing type String, =destroy, =dup, =copy, =wasMoved)
#      and this validator.nim into the same directory.
#   2. The subject_solution.nim must also export:
#         proc initString(s: var String; data: string)
#         proc getStr(s: String): string
#         proc mutateAt(s: var String; i: int; c: char)
#      If not, the validator will fail to compile.
#   3. nim r --mm:orc validator.nim

import std/assertions
import subject_solution

var testsPassed = 0
var testsFailed = 0

template check(name: string, cond: bool, msg: string = "") =
  if cond:
    testsPassed.inc()
    echo "  [PASS] ", name
  else:
    testsFailed.inc()
    echo "  [FAIL] ", name, " — ", msg

proc testRefCounting() =
  echo "--- Reference Counting ---"
  var a: String
  initString(a, "hello")
  check("init counter=1", a.p.counter == 1, "got " & $a.p.counter)
  
  block:
    var b {.used.} = a  # triggers =dup or =copy
    check("copy counter=2", a.p.counter == 2, "got " & $a.p.counter)
    check("shared payload", a.p == b.p, "payloads differ")
  
  check("counter back to 1 after scope exit", a.p.counter == 1, "got " & $a.p.counter)
  `=destroy`(a)

proc testCow() =
  echo "--- Copy-on-Write ---"
  var a: String
  initString(a, "hello")
  
  var b = a
  check("shared after copy", a.p == b.p)
  
  mutateAt(b, 0, 'H')
  check("detached after mutation", a.p != b.p, "still sharing payload")
  check("original unchanged", getStr(a) == "hello", "got " & getStr(a))
  check("copy mutated", getStr(b) == "Hello", "got " & getStr(b))
  check("original counter=1", a.p.counter == 1, "got " & $a.p.counter)
  check("copy counter=1", b.p.counter == 1, "got " & $b.p.counter)
  
  `=destroy`(b)
  `=destroy`(a)

proc testMoveSemantics() =
  echo "--- Move Semantics ---"
  var a: String
  initString(a, "test")
  let pBefore = a.p
  
  var b = move(a)
  check("move transfers pointer", b.p == pBefore, "pointer not transferred")
  check("move does not change counter", b.p.counter == 1, "got " & $b.p.counter)
  check("source nil after move", a.p == nil, "source not nil")
  
  `=destroy`(b)

proc testSelfCopy() =
  echo "--- Self-Copy Safety ---"
  var a: String
  initString(a, "self")
  let pBefore = a.p
  let cBefore = a.p.counter
  
  `=copy`(a, a)
  check("pointer preserved", a.p == pBefore, "pointer changed")
  check("counter preserved", a.p.counter == cBefore, "counter changed from " & $cBefore & " to " & $a.p.counter)
  check("data preserved", getStr(a) == "self", "got " & getStr(a))
  
  `=destroy`(a)

proc testDestroyAfterMove() =
  echo "--- Destroy After Move (double-free test) ---"
  var a: String
  initString(a, "tmp")
  var b = move(a)
  `=destroy`(b)
  # a is moved-from (nil), destroy should be no-op
  `=destroy`(a)
  testsPassed.inc()
  echo "  [PASS] no crash on destroy-after-move"

proc testMultipleCopies() =
  echo "--- Multiple Copies ---"
  var a: String
  initString(a, "chain")
  var b = a
  var c = a
  check("3 refs counter=3", a.p.counter == 3, "got " & $a.p.counter)
  
  `=destroy`(c)
  check("counter=2 after one destroy", a.p.counter == 2, "got " & $a.p.counter)
  `=destroy`(b)
  check("counter=1 after two destroys", a.p.counter == 1, "got " & $a.p.counter)
  `=destroy`(a)

proc testSinkOverwrite() =
  echo "--- Sink Overwrite ---"
  var a: String
  initString(a, "old")
  var b: String
  initString(b, "new")
  
  let oldP = a.p
  a = move(b)
  check("sink overwrites dest", a.p != oldP, "pointer didn't change")
  check("sink has new data", getStr(a) == "new", "got " & getStr(a))
  check("source nil after sink", b.p == nil, "source not nil")
  
  `=destroy`(a)

proc main() =
  echo "============================================"
  echo "  Validator: subject_solution.nim"
  echo "============================================"
  
  testRefCounting()
  testCow()
  testMoveSemantics()
  testSelfCopy()
  testDestroyAfterMove()
  testMultipleCopies()
  testSinkOverwrite()
  
  echo ""
  echo "============================================"
  echo "  Results: ", testsPassed, " passed, ", testsFailed, " failed"
  echo "============================================"
  
  if testsFailed > 0:
    quit(1)

main()
