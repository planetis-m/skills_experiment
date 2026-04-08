## C05: Accessors should treat invalid index and missing required data as
##      contract violations that raise ValueError (or a specific exception).

import std/assertions

type
  StringTable = object
    keys: seq[string]
    values: seq[string]

proc newStringTable(pairs: openArray[(string, string)]): StringTable =
  for (k, v) in pairs:
    result.keys.add(k)
    result.values.add(v)

proc atIndex(tbl: StringTable; i: int): string =
  if i < 0 or i >= tbl.keys.len:
    raise newException(ValueError, "index out of bounds: " & $i)
  result = tbl.values[i]

proc get(tbl: StringTable; key: string): string =
  for i in 0..<tbl.keys.len:
    if tbl.keys[i] == key:
      return tbl.values[i]
  raise newException(ValueError, "missing required key: " & key)

block valid_access:
  let tbl = newStringTable([("name", "Alice"), ("age", "30")])
  doAssert tbl.atIndex(0) == "Alice"
  doAssert tbl.atIndex(1) == "30"
  doAssert tbl.get("name") == "Alice"
  doAssert tbl.get("age") == "30"

block invalid_index_raises:
  let tbl = newStringTable([("name", "Alice")])
  doAssertRaises(ValueError):
    discard tbl.atIndex(-1)
  doAssertRaises(ValueError):
    discard tbl.atIndex(5)

block missing_key_raises:
  let tbl = newStringTable([("name", "Alice")])
  doAssertRaises(ValueError):
    discard tbl.get("nonexistent")

block exception_type_is_exact:
  let tbl = newStringTable([("name", "Alice")])
  # Verify we catch ValueError specifically, not just a parent type
  var caught = false
  try:
    discard tbl.atIndex(99)
  except ValueError:
    caught = true
  except CatchableError:
    doAssert false, "caught as CatchableError, not ValueError"
  doAssert caught

echo "C05: PASS"
