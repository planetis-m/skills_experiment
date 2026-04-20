var failures = 0
var passed = 0

proc check(condition: bool; msg: string) =
  if condition:
    passed += 1
  else:
    failures += 1
    echo "  FAIL: " & msg

proc summary() =
  echo "Passed: " & $passed & "  Failed: " & $failures
  if failures > 0:
    quit "TESTS FAILED", 1
  else:
    echo "ALL TESTS PASSED"

check true, "ok"
check true, "ok"

summary()
