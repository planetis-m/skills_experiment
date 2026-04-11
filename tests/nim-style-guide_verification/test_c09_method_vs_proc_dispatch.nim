## C09: method uses dynamic dispatch; proc overloads use static dispatch

type
  Node = ref object of RootObj
  Leaf = ref object of Node

method kind(x: Node): string {.base.} =
  "node"

method kind(x: Leaf): string =
  "leaf"

proc kindProc(x: Node): string =
  "node"

proc kindProc(x: Leaf): string =
  "leaf"

let leaf = Leaf()
let asNode: Node = leaf

doAssert kind(asNode) == "leaf"
doAssert kindProc(asNode) == "node"
doAssert kindProc(leaf) == "leaf"

echo "C09: PASS"
