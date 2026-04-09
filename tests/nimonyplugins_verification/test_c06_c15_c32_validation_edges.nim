# Test C06, C15, C32: malformed constructed trees become ErrT, and addEmptyNode4 emits four placeholders.
import nimony/lib/nimonyplugins
import std/strutils

let badCall = createTree(CallX)
let badCallNode = snapshot(badCall)
doAssert $badCallNode.tag == $ErrT
doAssert renderNode(badCallNode).contains("missing child")

let badPragma = createTree(PragmaP)
let badPragmaNode = snapshot(badPragma)
doAssert $badPragmaNode.tag == $ErrT
doAssert renderNode(badPragmaNode).contains("missing child")

var t = createTree()
t.withTree(StmtsS, NoLineInfo):
  t.addEmptyNode4()

let rendered = renderTree(t)
doAssert rendered.count(".") == 4

echo "C06_C15_C32_edges: PASS"
