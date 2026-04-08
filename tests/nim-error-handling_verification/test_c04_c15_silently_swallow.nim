# C04, C15: Empty except blocks silently swallow exceptions, hiding errors.
# Verify that an exception caught by an empty except block does NOT propagate.

proc raisesValueError() =
  raise newException(ValueError, "test error")

proc testSwallow() =
  var caught = false
  try:
    raisesValueError()
  except CatchableError:
    discard  # silently swallowed
  # If we reach here, the exception was swallowed (hidden)
  caught = true
  doAssert caught, "Should have reached here after swallow"

proc testNoSwallow() =
  var outerCaught = false
  try:
    try:
      raisesValueError()
    except CatchableError:
      raise  # re-raise
  except CatchableError:
    outerCaught = true
  doAssert outerCaught, "Re-raised exception should propagate to outer handler"

testSwallow()
testNoSwallow()
echo "C04: PASS"
