Retry loop example that separates retriable failures from final failures.

```nim
type
  RetryDecision = enum
    retryNow, failFinal

proc classifyFailure(statusCode: int): RetryDecision =
  case statusCode
  of 408, 429, 500, 502, 503, 504:
    retryNow
  else:
    failFinal

proc requestWithRetry(maxAttempts: int; responses: seq[int]): string =
  for i, status in responses:
    if status == 200:
      return "ok"
    if classifyFailure(status) == retryNow and i + 1 < maxAttempts:
      continue
    raise newException(IOError,
      "request failed after attempt " & $(i + 1) & " with status " & $status)
  raise newException(IOError, "request produced no successful response")
```

When to use
- Use this shape when some failures are retryable and others should fail fast.
- Raise once retries are exhausted instead of silently returning a partial result.
