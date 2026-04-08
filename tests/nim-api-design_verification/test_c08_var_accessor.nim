## C08: var T overloads only for reference-like results (string, seq).

import std/algorithm

type
  Config = object
    name: string
    tags: seq[string]
    count: int

proc getName(c: var Config): var string = result = c.name
proc getTags(c: var Config): var seq[string] = result = c.tags
# No var overload for count (int) — scalars use direct assignment

block var_string_mutation:
  var c = Config(name: "hello", tags: @[], count: 0)
  c.getName().add("!")
  doAssert c.name == "hello!"

block var_seq_mutation:
  var c = Config(name: "", tags: @["b", "a"], count: 0)
  c.getTags().sort()
  doAssert c.tags == @["a", "b"]
  c.getTags()[0] = "z"
  doAssert c.tags[0] == "z"

block scalars_direct_assignment:
  var c = Config(name: "", tags: @[], count: 10)
  c.count = 20
  doAssert c.count == 20

echo "C08: PASS"
