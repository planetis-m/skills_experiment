# C12, C13: Retriable vs final errors. On final failure, raise.

type
  RetryPolicy = object
    maxAttempts: int

proc shouldRetry(attempt, maxAttempts: int; isRetriable: bool): bool =
  isRetriable and attempt < maxAttempts

proc requestWithRetry(maxAttempts: int; responses: seq[tuple[retriable: bool, ok: bool]]): string =
  for i, resp in responses:
    if resp.ok:
      return "ok"
    if shouldRetry(i + 1, maxAttempts, resp.retriable):
      continue
    else:
      raise newException(IOError, "final failure at attempt " & $(i + 1))
  raise newException(IOError, "exhausted retries")

proc test() =
  doAssert requestWithRetry(3, @[(retriable: true, ok: true)]) == "ok"

  doAssert requestWithRetry(3, @[
    (retriable: true, ok: false),
    (retriable: true, ok: true)
  ]) == "ok"

  var caught = false
  try:
    discard requestWithRetry(3, @[(retriable: false, ok: false)])
  except IOError:
    caught = true
  doAssert caught

  caught = false
  try:
    discard requestWithRetry(2, @[
      (retriable: true, ok: false),
      (retriable: true, ok: false),
      (retriable: true, ok: false)
    ])
  except IOError:
    caught = true
  doAssert caught

test()
echo "C12: PASS"
