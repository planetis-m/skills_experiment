# C08: Multiple exception types can share a handler.

proc test() =
  var count = 0

  # ValueError, IOError, OSError all caught by shared handler
  try:
    raise newException(ValueError, "v")
  except ValueError, IOError, OSError:
    inc count

  try:
    raise newException(IOError, "i")
  except ValueError, IOError, OSError:
    inc count

  try:
    raise newException(OSError, "o")
  except ValueError, IOError, OSError:
    inc count

  # CatchableError should NOT be caught by the specific handler
  var catchableReached = false
  try:
    raise newException(CatchableError, "generic")
  except ValueError, IOError, OSError:
    doAssert false, "CatchableError should not match specific handler"
  except CatchableError:
    catchableReached = true
  doAssert catchableReached

  doAssert count == 3, "All three types should be caught by shared handler"

test()
echo "C08_multi: PASS"
