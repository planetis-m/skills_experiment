# C16, C17: parseJson raises CatchableError on invalid input.
# CatchableError catches multiple exception types (ValueError, IOError, JsonParsingError).

import std/json

proc test() =
  # C16: Invalid JSON raises CatchableError
  var caught = false
  try:
    discard parseJson("{invalid}")
  except CatchableError:
    caught = true
  doAssert caught, "Invalid JSON should raise CatchableError"

  # C16: Empty/broken JSON raises
  var caught2 = false
  try:
    discard parseJson("")
  except CatchableError:
    caught2 = true
  doAssert caught2, "Empty JSON should raise CatchableError"

  # C17: Multiple exception types caught by CatchableError
  var count = 0
  try:
    raise newException(ValueError, "v")
  except CatchableError:
    inc count

  try:
    raise newException(IOError, "i")
  except CatchableError:
    inc count

  try:
    discard parseJson("not json at all")
  except CatchableError:
    inc count

  doAssert count == 3, "All three exception types should be caught by CatchableError, got " & $count

test()
echo "C16: PASS"
