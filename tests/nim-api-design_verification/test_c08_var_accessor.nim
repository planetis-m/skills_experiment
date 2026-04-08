## C08: var T accessor overloads for mutable reference-like results (string, seq).

import std/algorithm

type
  Config = object
    name: string
    tags: seq[string]
    count: int

proc getName(c: Config): lent string = result = c.name
proc getTags(c: Config): lent seq[string] = result = c.tags
proc getCount(c: Config): int = result = c.count

proc getNameMut(c: var Config): var string = result = c.name
proc getTagsMut(c: var Config): var seq[string] = result = c.tags
# No var overload for count (int) — scalars don't need them

block var_string_allows_mutation:
  var cfg = Config(name: "original", tags: @[], count: 0)
  cfg.getNameMut() = "modified"
  doAssert cfg.name == "modified"
  doAssert cfg.getName() == "modified"

block var_string_enables_in_place_ops:
  var cfg = Config(name: "hello", tags: @[], count: 0)
  cfg.getNameMut().add("!")
  doAssert cfg.name == "hello!"

block var_seq_allows_mutation:
  var cfg = Config(name: "", tags: @["a"], count: 0)
  cfg.getTagsMut().add("b")
  doAssert cfg.tags == @["a", "b"]

block var_seq_sort_modifies_source:
  var cfg = Config(name: "", tags: @["y", "x"], count: 0)
  cfg.getTagsMut().sort()
  doAssert cfg.tags == @["x", "y"]
  cfg.getTagsMut()[0] = "z"
  doAssert cfg.tags[0] == "z"

block scalars_use_direct_assignment:
  var cfg = Config(name: "", tags: @[], count: 10)
  cfg.count = 20  # direct assignment — no var accessor needed
  doAssert cfg.getCount() == 20

block lent_works_on_let:
  let cfg = Config(name: "readonly", tags: @["immutable"], count: 1)
  doAssert cfg.getName() == "readonly"
  doAssert cfg.getTags()[0] == "immutable"

echo "C08: PASS"
