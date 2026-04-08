# Bool-return parse helpers

Wrap parsing operations that can fail into a simple bool API.

```nim
import std/json

proc parseFirstCallArgs[T](data: string; dst: var T): bool =
  result = false
  try:
    dst = fromJson(parseJson(data), T)
    result = true
  except CatchableError:
    result = false

# Usage:
var port: int
if parseFirstCallArgs("8080", port):
  echo "Port: ", port
else:
  echo "Invalid input"
```

Key points:
- Catches `CatchableError` — covers all JSON syntax errors.
- Returns `false` on any failure, `true` + populated `dst` on success.
- **Does not catch type mismatches** — `getInt()` on a string node returns 0 silently. Validate types separately if needed.
