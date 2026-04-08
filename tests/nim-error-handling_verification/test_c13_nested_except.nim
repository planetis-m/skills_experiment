# C13: Inner except catches don't prevent outer propagation when re-raised.

proc test() =
  var outerCaught = false
  var innerCaught = false

  try:
    try:
      raise newException(ValueError, "inner")
    except ValueError:
      innerCaught = true
      raise  # re-raise to outer
  except CatchableError:
    outerCaught = true

  doAssert innerCaught, "Inner handler should catch first"
  doAssert outerCaught, "Re-raised exception should reach outer handler"

proc testNoReraise() =
  # If inner catches without re-raising, outer sees nothing
  var outerCaught = false
  var innerCaught = false

  try:
    try:
      raise newException(ValueError, "inner")
    except ValueError:
      innerCaught = true
      # no raise — swallowed
  except CatchableError:
    outerCaught = true

  doAssert innerCaught, "Inner handler should catch"
  doAssert not outerCaught, "Outer should NOT catch if inner swallowed"

test()
testNoReraise()
echo "C13: PASS"
