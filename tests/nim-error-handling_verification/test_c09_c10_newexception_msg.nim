# C09, C10: newException creates exception, getCurrentExceptionMsg returns message.

proc test() =
  # C09: newException creates exception with message
  var exc = newException(ValueError, "test message 123")
  doAssert exc.msg == "test message 123", "newException should set msg"

  # C10: getCurrentExceptionMsg returns message in except block
  var caughtMsg = ""
  try:
    raise newException(IOError, "io error msg")
  except IOError:
    caughtMsg = getCurrentExceptionMsg()
  doAssert caughtMsg == "io error msg", "getCurrentExceptionMsg should return 'io error msg', got: " & caughtMsg

test()
echo "C09: PASS"
