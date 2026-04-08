# C07, C12: Exception translation at module boundaries.
# Catch one type, raise another with context from getCurrentExceptionMsg().

import std/strutils

proc lowLevelWork() =
  raise newException(OSError, "file not found")

proc highLevelApi() =
  try:
    lowLevelWork()
  except CatchableError:
    raise newException(IOError, "highLevelApi failed: " & getCurrentExceptionMsg())

proc test() =
  var caught = false
  var msg = ""
  try:
    highLevelApi()
  except IOError:
    caught = true
    msg = getCurrentExceptionMsg()
  except CatchableError:
    doAssert false, "Should catch IOError, not generic CatchableError"

  doAssert caught, "IOError should be caught"
  doAssert msg.contains("highLevelApi failed"), "Should contain context: " & msg
  doAssert msg.contains("file not found"), "Should contain original message: " & msg

test()
echo "C07: PASS"
