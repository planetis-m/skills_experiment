# Test C13, C14, C15: literals, symUse, empty nodes
import nimony/lib/nimonyplugins

var t = createTree()
t.withTree(StmtsS, NoLineInfo):
  t.addDotToken()
  t.addStrLit "hello"
  t.addIntLit 42
  t.addUIntLit 100'u64
  t.addFloatLit 3.14
  t.addCharLit 'x'
  t.addIdent "myIdent"
  t.addSymUse "someSym"
  t.addEmptyNode()
  t.addEmptyNode2()
  t.addEmptyNode3()

let rendered = renderTree(t)
doAssert rendered.len > 0

echo "C13_C14_C15: PASS"
