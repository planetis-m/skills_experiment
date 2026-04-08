# C15: Exception object access may use either `as` binding or
# `getCurrentException()`. Use `getCurrentExceptionMsg()` when only the message
# text matters.

proc test() =
  # Access .msg via `as` binding.
  var msgViaAs = ""
  try:
    raise newException(OSError, "something broke")
  except OSError as e:
    msgViaAs = e.msg
  doAssert msgViaAs == "something broke", "Should access e.msg: " & msgViaAs

  # Access the same current exception object via getCurrentException().
  var msgViaCurrent = ""
  try:
    raise newException(IOError, "io")
  except IOError:
    let e = getCurrentException()
    msgViaCurrent = e.msg
  doAssert msgViaCurrent == "io", "Should access getCurrentException().msg: " &
      msgViaCurrent

  # Both styles support translation when the handler needs the object.
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

  var wrappedAs = ""
  try:
    wrapViaAs()
  except IOError:
    wrappedAs = getCurrentExceptionMsg()
  doAssert wrappedAs == "wrapViaAs: disk"

  var wrappedCurrent = ""
  try:
    wrapViaCurrent()
  except IOError:
    wrappedCurrent = getCurrentExceptionMsg()
  doAssert wrappedCurrent == "wrapViaCurrent: socket"

test()
echo "C15_binding_styles: PASS"
