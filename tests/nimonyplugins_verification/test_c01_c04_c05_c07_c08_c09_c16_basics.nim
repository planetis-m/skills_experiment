# Test C01, C04, C05, C07, C08, C09, C16: NifBuilder basics, createTree, withTree, isEmpty, snapshot, kind/exprKind, renderTree
import nimony/lib/nimonyplugins

# C05: createTree() starts empty
var t = createTree()
doAssert t.isEmpty

# C07: withTree emits balanced node
t.withTree(CallX, NoLineInfo):
  t.addIdent "echo"
  t.addStrLit "hello"

# C04: isEmpty is false after building
doAssert not t.isEmpty

# C03/C04: snapshot requires non-empty tree
var n = snapshot(t)

# C08: kind
doAssert n.kind == ParLe

# C09: exprKind
doAssert n.exprKind == CallX

# C16: renderTree
let rendered = renderTree(t)
doAssert rendered.len > 0

echo "C01_C04_C05_C07_C08_C09_C16: PASS"
