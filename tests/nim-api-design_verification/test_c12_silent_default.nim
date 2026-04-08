## C12: Accessors must not silently return defaults for missing data.

type
  Lookup = object
    data: seq[(string, string)]

proc getSilent(l: Lookup; key: string): string =
  for (k, v) in l.data:
    if k == key: return v
  return ""  # anti-pattern: silently returns default

proc getRaise(l: Lookup; key: string): string =
  for (k, v) in l.data:
    if k == key: return v
  raise newException(ValueError, "key not found: " & key)

let l = Lookup(data: @[("name", "Alice")])

# Silent version hides missing key — "" is indistinguishable from legitimate empty
doAssert getSilent(l, "missing") == ""
doAssert getSilent(l, "name") == "Alice"

# Raising version surfaces the problem
doAssert getRaise(l, "name") == "Alice"
doAssertRaises(ValueError):
  discard getRaise(l, "missing")

echo "C12: PASS"
