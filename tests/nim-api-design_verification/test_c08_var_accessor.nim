## C08: var T accessor overloads for mutable reference-like results (string, seq)

import std/algorithm

type
  Config = object
    name: string
    tags: seq[string]
    count: int
    ratio: float

# --- Read accessors (lent) ---
proc getName(c: Config): lent string = result = c.name
proc getTags(c: Config): lent seq[string] = result = c.tags
proc getCount(c: Config): lent int = result = c.count
proc getRatio(c: Config): lent float = result = c.ratio

# --- var overloads for mutable reference-like types (string, seq) ---
proc getNameMut(c: var Config): var string = result = c.name
proc getTagsMut(c: var Config): var seq[string] = result = c.tags

# Note: No var overloads for count (int) or ratio (float) — scalars don't need them.

# --- Test 1: var string overload allows mutation of underlying data ---
block:
  var cfg = Config(name: "original", tags: @[], count: 5, ratio: 1.0)
  cfg.getNameMut() = "modified"
  doAssert cfg.name == "modified", "Mutation through var string accessor failed"
  # Also verify the lent accessor sees the change
  doAssert cfg.getName() == "modified"

# --- Test 2: var seq overload allows mutation ---
block:
  var cfg = Config(name: "test", tags: @["a"], count: 0, ratio: 0.0)
  cfg.getTagsMut().add("b")
  doAssert cfg.tags.len == 2
  doAssert cfg.tags[0] == "a"
  doAssert cfg.tags[1] == "b"

# --- Test 3: mutation through var seq modifies source object ---
block:
  var cfg = Config(name: "", tags: @["x", "y"], count: 0, ratio: 0.0)
  # Sort tags in-place through the var accessor
  cfg.getTagsMut().sort()
  doAssert cfg.tags == @["x", "y"]  # already sorted
  cfg.getTagsMut()[0] = "z"
  doAssert cfg.tags[0] == "z", "Source object not modified"
  doAssert cfg.tags == @["z", "y"]

# --- Test 4: var overload makes sense for string/seq, not for int/float ---
block:
  # For int/float, mutation is done by direct assignment on the object,
  # not through a var accessor. Demonstrate the idiomatic pattern:
  var cfg = Config(name: "", tags: @[], count: 10, ratio: 3.14)
  # Direct assignment — no var accessor needed for scalars
  cfg.count = 20
  cfg.ratio = 2.71
  doAssert cfg.getCount() == 20
  doAssert cfg.getRatio() == 2.71
  
  # But for string, the var accessor enables in-place mutation patterns:
  var cfg2 = Config(name: "hello", tags: @["world"], count: 0, ratio: 0.0)
  cfg2.getNameMut().add("!")
  doAssert cfg2.name == "hello!", "var string accessor enables in-place append"

# --- Test 5: lent accessors work on immutable holders ---
block:
  let cfg = Config(name: "readonly", tags: @["immutable"], count: 1, ratio: 1.0)
  doAssert cfg.getName() == "readonly"
  doAssert cfg.getTags()[0] == "immutable"
  doAssert cfg.getCount() == 1

echo "C08: PASS"
