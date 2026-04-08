# C15: Catch with `as` binding to access exception object.

import std/strutils

proc test() =
  # Access .msg via `as` binding
  var msg = ""
  try:
    raise newException(OSError, "something broke")
  except OSError as e:
    msg = e.msg
  doAssert msg == "something broke", "Should access e.msg: " & msg

  # Access exception name
  var name = ""
  try:
    raise newException(ValueError, "val")
  except ValueError as e:
    name = $e.name
  doAssert "ValueError" in name, "Should contain type name: " & name

  # CatchableError as base with `as` binding
  var caught = false
  try:
    raise newException(IOError, "io")
  except CatchableError as e:
    caught = true
    doAssert e.msg == "io"
  doAssert caught

test()
echo "C15_as: PASS"
