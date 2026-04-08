# Named Result Objects vs Status Tuples

Demonstrates why named objects are preferred over boolean-status tuples.

## Anti-pattern: status tuple

```nim
proc render(): tuple[ok: bool, payload: seq[byte], errorMessage: string] =
  # Caller must check .ok manually — easy to forget
  # errorMessage is a string, not a typed exception
  # payload type is seq[byte] even when ok is false (what does it contain?)
  discard
```

Problems:
- Caller can forget to check `ok` and use `payload` anyway.
- `errorMessage` is an unstructured string — no exception type hierarchy.
- All fields exist regardless of success/failure — unclear what's valid when.

## Correct: named result type or raise

```nim
type
  RenderResult = object
    payload: seq[byte]
    warnings: seq[string]

proc render*(): RenderResult =
  ## Raises ValueError on invalid input, returns RenderResult on success.
  ## The caller gets a fully-initialized, type-safe result.
  ## Warnings are optional (empty seq) — not a separate error channel.
  discard
```

Or for APIs that need non-exception error handling:

```nim
type
  RenderError = enum
    reInvalidInput
    reDeviceLost
    reOutOfMemory

  RenderOutcome = object
    case ok: bool
    of true:
      payload: seq[byte]
    of false:
      error: RenderError
```

## Key points

- Named types are self-documenting and enforce structure.
- Use exceptions for contract violations; use typed result objects for
  expected outcomes.
- Object variants (`case ok: bool`) model success/failure explicitly when
  exceptions aren't appropriate.
- Stdlib never uses `(ok: bool, payload: T, msg: string)` tuples in public APIs.
