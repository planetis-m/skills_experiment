# C14: Try block can contain multiple statements; except catches from any.

proc test() =
  var which = 0
  try:
    let a = 1  # fine
    let b = 2  # fine
    raise newException(ValueError, "from statement 3")
    let c = 3  # unreachable
  except CatchableError:
    which = 1
  doAssert which == 1, "Should catch from statement 3"

  # Exception from first statement
  try:
    raise newException(IOError, "from statement 1")
    let d = 4  # unreachable
  except CatchableError:
    which = 2
  doAssert which == 2, "Should catch from statement 1"

test()
echo "C14: PASS"
