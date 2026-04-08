# C14: try/finally for resource cleanup.

type
  FakeResource = object
    closed: bool

proc closeResource(r: var FakeResource) =
  r.closed = true

proc test() =
  # finally runs even when no exception
  var res = FakeResource(closed: false)
  try:
    discard
  finally:
    closeResource(res)
  doAssert res.closed, "finally should run on normal exit"

  # finally runs when exception occurs, then except catches
  res = FakeResource(closed: false)
  var caught = false
  try:
    try:
      raise newException(ValueError, "test")
    finally:
      closeResource(res)
  except ValueError:
    caught = true
  doAssert res.closed, "finally should run before except"
  doAssert caught

  # Exception propagates through finally to outer handler
  res = FakeResource(closed: false)
  caught = false
  try:
    try:
      raise newException(IOError, "inner")
    finally:
      closeResource(res)
  except IOError:
    caught = true
  doAssert res.closed
  doAssert caught, "Exception should propagate through finally"

test()
echo "C14: PASS"
