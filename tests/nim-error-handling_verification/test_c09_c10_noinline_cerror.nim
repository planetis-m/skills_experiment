# C09, C10: {.noinline.} on error-raising proc, C library error translation.

import std/strutils

proc raiseCustomError*(context: string) {.noinline.} =
  let code = 42
  let detail = case code
    of 0: "no error"
    of 42: "file not found"
    else: "unknown"
  raise newException(IOError, context & ": " & detail & " (code " & $code & ")")

proc test() =
  var caught = false
  var msg = ""
  try:
    raiseCustomError("loadDocument")
  except IOError:
    caught = true
    msg = getCurrentExceptionMsg()
  doAssert caught
  doAssert "loadDocument" in msg, "Should contain context: " & msg
  doAssert "file not found" in msg, "Should contain detail: " & msg
  doAssert "code 42" in msg, "Should contain code: " & msg

test()
echo "C09: PASS"
