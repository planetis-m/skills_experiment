# Test C12: add(t, childTree) appends another whole NifBuilder
import nimony/lib/nimonyplugins

var child = createTree()
child.addIdent "hello"

var parent = createTree()
parent.withTree(StmtsS, NoLineInfo):
  parent.add(child)

doAssert not parent.isEmpty

echo "C12: PASS"
