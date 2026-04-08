# C08: Bool-return parse helpers catch CatchableError at the boundary and return false.
# This works for JSON syntax errors. Type mismatches are silent (getInt on string returns 0).

import std/json

proc parseIntHelper(data: string; dst: var int): bool =
  result = false
  try:
    let j = parseJson(data)
    dst = j.getInt()
    result = true
  except CatchableError:
    result = false

proc test() =
  # Valid input returns true
  var x: int
  doAssert parseIntHelper("42", x)
  doAssert x == 42

  # Invalid JSON returns false (doesn't crash)
  var y: int
  doAssert not parseIntHelper("not json", y)

  # Empty string returns false
  var w: int
  doAssert not parseIntHelper("", w)

  # Valid JSON, wrong type: getInt on string returns 0 silently
  # This is a nuance — the parse helper pattern catches syntax errors,
  # not type mismatches
  var z: int
  doAssert parseIntHelper("\"hello\"", z)  # returns true, z = 0
  doAssert z == 0

test()
echo "C08: PASS"
