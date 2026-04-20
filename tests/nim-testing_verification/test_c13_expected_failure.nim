import std/strutils

block expected_failure_pattern:
  proc expectValueError(action: proc()) =
    var raised = false
    try:
      action()
    except ValueError:
      raised = true
    doAssert raised, "C13: expected ValueError"

  expectValueError(proc() = raise newException(ValueError, "test"))
  echo "C13: PASS"
