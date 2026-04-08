# C11: CatchableError is the common base for all catchable exceptions.

proc test() =
  # ValueError is a CatchableError
  var caughtValue = false
  try:
    raise newException(ValueError, "val")
  except CatchableError:
    caughtValue = true
  doAssert caughtValue, "ValueError should be caught by CatchableError"

  # IOError is a CatchableError
  var caughtIO = false
  try:
    raise newException(IOError, "io")
  except CatchableError:
    caughtIO = true
  doAssert caughtIO, "IOError should be caught by CatchableError"

  # OSError is a CatchableError
  var caughtOS = false
  try:
    raise newException(OSError, "os")
  except CatchableError:
    caughtOS = true
  doAssert caughtOS, "OSError should be caught by CatchableError"

  # Defect (like AccessViolationDefect) should NOT be caught by CatchableError
  # (Defect inherits from Exception, not CatchableError)

test()
echo "C11: PASS"
