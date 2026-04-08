## C05: Accessors should raise on invalid index and missing required data.

type
  Lookup = object
    keys: seq[string]
    vals: seq[string]

proc at(l: Lookup; i: int): string =
  if i < 0 or i >= l.vals.len:
    raise newException(ValueError, "index " & $i & " out of bounds")
  result = l.vals[i]

proc get(l: Lookup; key: string): string =
  for i in 0..<l.keys.len:
    if l.keys[i] == key: return l.vals[i]
  raise newException(ValueError, "missing key: " & key)

let l = Lookup(keys: @["name", "age"], vals: @["Alice", "30"])

doAssert l.at(0) == "Alice"
doAssert l.get("age") == "30"

doAssertRaises(ValueError): discard l.at(-1)
doAssertRaises(ValueError): discard l.at(5)
doAssertRaises(ValueError): discard l.get("missing")

echo "C05: PASS"
