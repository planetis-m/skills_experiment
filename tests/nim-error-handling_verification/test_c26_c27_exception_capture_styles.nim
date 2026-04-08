# C26, C27: Prefer a simple default for exception access, but treat equivalent
# capture styles as compatibility-level alternatives. Use
# getCurrentExceptionMsg() when only the message text is needed.

proc wrapViaAs() =
  try:
    raise newException(OSError, "disk")
  except OSError as e:
    raise newException(IOError, "wrapViaAs: " & e.msg)

proc wrapViaCurrent() =
  try:
    raise newException(OSError, "socket")
  except OSError:
    let e = getCurrentException()
    raise newException(IOError, "wrapViaCurrent: " & e.msg)

proc wrapViaMsg() =
  try:
    raise newException(OSError, "audit write failed")
  except OSError:
    raise newException(IOError, "writeAuditLine failed: " & getCurrentExceptionMsg())

proc test() =
  var msg = ""
  try:
    wrapViaAs()
  except IOError:
    msg = getCurrentExceptionMsg()
  doAssert msg == "wrapViaAs: disk"

  msg = ""
  try:
    wrapViaCurrent()
  except IOError:
    msg = getCurrentExceptionMsg()
  doAssert msg == "wrapViaCurrent: socket"

  msg = ""
  try:
    wrapViaMsg()
  except IOError:
    msg = getCurrentExceptionMsg()
  doAssert msg == "writeAuditLine failed: audit write failed"

test()
echo "C26_C27: PASS"
