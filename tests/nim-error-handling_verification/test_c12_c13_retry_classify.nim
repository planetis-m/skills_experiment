# C12, C13: Retriable vs final errors. On final failure, raise.

type
  RetryDecision = enum
    retryNow, failFinal

proc classifyFailure(statusCode: int): RetryDecision =
  case statusCode
  of 408, 429, 500, 502, 503, 504:
    retryNow
  else:
    failFinal

proc shouldRetry(attempt, maxAttempts: int; statusCode: int): bool =
  classifyFailure(statusCode) == retryNow and attempt < maxAttempts

proc requestWithRetry(maxAttempts: int; responses: openArray[int]): string =
  for i, statusCode in responses:
    let attempt = i + 1
    if statusCode == 200:
      return "ok"
    if not shouldRetry(attempt, maxAttempts, statusCode):
      raise newException(IOError,
        "request failed at attempt " & $attempt & " with status " & $statusCode)
  raise newException(IOError, "request produced no successful response")

proc test() =
  doAssert requestWithRetry(3, @[200]) == "ok"

  doAssert requestWithRetry(3, @[503, 200]) == "ok"

  var caught = false
  try:
    discard requestWithRetry(3, @[404])
  except IOError:
    caught = true
  doAssert caught

  caught = false
  try:
    discard requestWithRetry(2, @[503, 503, 503])
  except IOError:
    caught = true
  doAssert caught

test()
echo "C12: PASS"
