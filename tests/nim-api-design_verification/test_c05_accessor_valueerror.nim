## C05: Accessors should treat invalid index and missing required data as
##      contract violations that raise ValueError.

import std/assertions

# --- Simple container with accessor ---
type
  StringTable = object
    keys: seq[string]
    values: seq[string]

proc newStringTable(pairs: openArray[(string, string)]): StringTable =
  for (k, v) in pairs:
    result.keys.add(k)
    result.values.add(v)

# Accessor by index — raises ValueError on invalid index
proc atIndex(tbl: StringTable; i: int): string =
  if i < 0 or i >= tbl.keys.len:
    raise newException(ValueError, "index out of bounds: " & $i)
  result = tbl.values[i]

# Accessor by key — raises ValueError on missing required data
proc get(tbl: StringTable; key: string): string =
  for i in 0..<tbl.keys.len:
    if tbl.keys[i] == key:
      return tbl.values[i]
  raise newException(ValueError, "missing required key: " & key)

proc main() =
  let tbl = newStringTable([("name", "Alice"), ("age", "30")])

  # ---- Valid access works ----
  doAssert tbl.atIndex(0) == "Alice"
  doAssert tbl.atIndex(1) == "30"
  doAssert tbl.get("name") == "Alice"
  doAssert tbl.get("age") == "30"

  # ---- Invalid index raises ValueError ----
  doAssertRaises(ValueError):
    discard tbl.atIndex(-1)
  doAssertRaises(ValueError):
    discard tbl.atIndex(5)

  # ---- Missing required key raises ValueError ----
  doAssertRaises(ValueError):
    discard tbl.get("nonexistent")

  # ---- Verify exception type is exactly ValueError (not a subclass) ----
  # In Nim, exception types are concrete, so catching ValueError means
  # it's exactly the type we raised. Let's verify explicitly:
  block:
    var caughtValueError = false
    var caughtOther = false
    try:
      discard tbl.atIndex(99)
    except ValueError:
      let e = getCurrentException()
      doAssert e.name == "ValueError", "expected ValueError, got: " & $e.name
      caughtValueError = true
    except CatchableError:
      caughtOther = true
    doAssert caughtValueError, "ValueError was not caught"
    doAssert not caughtOther, "caught as CatchableError instead of ValueError"

  block:
    var caughtValueError = false
    try:
      discard tbl.get("missing_key")
    except ValueError:
      let e = getCurrentException()
      doAssert e.name == "ValueError", "expected ValueError, got: " & $e.name
      caughtValueError = true
    except CatchableError:
      discard  # should not reach here
    doAssert caughtValueError, "ValueError was not caught for missing key"

  echo "C05: PASS"

main()
