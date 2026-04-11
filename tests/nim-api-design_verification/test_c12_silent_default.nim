## C12: Required accessors must not silently default on missing data.
## Explicit optional access such as getOrDefault is fine as a secondary path.

type
  Lookup = object
    data: seq[(string, string)]

proc getSilent(l: Lookup; key: string): string =
  for (k, v) in l.data:
    if k == key: return v
  result = ""  # anti-pattern: silently returns default

proc getOrDefault(l: Lookup; key: string; default = ""): string =
  for (k, v) in l.data:
    if k == key: return v
  result = default

proc getRaise(l: Lookup; key: string): string =
  for (k, v) in l.data:
    if k == key: return v
  raise newException(ValueError, "key not found: " & key)

let l = Lookup(data: @[("name", "Alice")])

# Silent version hides missing key — "" is indistinguishable from legitimate empty
doAssert getSilent(l, "missing") == ""
doAssert getSilent(l, "name") == "Alice"

# Explicit optional path is acceptable because the default is part of the API.
doAssert getOrDefault(l, "name") == "Alice"
doAssert getOrDefault(l, "missing") == ""
doAssert getOrDefault(l, "missing", "n/a") == "n/a"

# Raising version surfaces the problem
doAssert getRaise(l, "name") == "Alice"
doAssertRaises(ValueError):
  discard getRaise(l, "missing")

echo "C12: PASS"
