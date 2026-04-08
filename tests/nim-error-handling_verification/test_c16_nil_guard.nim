# C16: Guard resource creation — check nil and raise immediately.

type
  RawHandle = distinct pointer

proc createResource(shouldFail: bool): RawHandle =
  if shouldFail:
    RawHandle(nil)
  else:
    RawHandle(unsafeAddr result)

proc acquireResource*(shouldFail: bool): RawHandle =
  result = createResource(shouldFail)
  if pointer(result) == nil:
    raise newException(IOError, "failed to acquire resource")

proc test() =
  let h = acquireResource(false)
  doAssert pointer(h) != nil

  var caught = false
  try:
    discard acquireResource(true)
  except IOError:
    caught = true
  doAssert caught

test()
echo "C16: PASS"
