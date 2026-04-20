import testlib

var failures = 0
var passed = 0

proc check(condition: bool; msg: string) =
  if condition:
    passed += 1
  else:
    failures += 1
    echo "  FAIL: " & msg

check true, "pass 1"
check true, "pass 2"
check false, "fail 1"
check true, "pass 3"

doAssert passed == 3, "C07: passed count must be 3, got " & $passed
doAssert failures == 1, "C07: failures count must be 1, got " & $failures

echo "C07: PASS"
