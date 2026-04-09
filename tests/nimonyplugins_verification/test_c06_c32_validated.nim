# Test C06, C32: validated createTree with kind+children
import nimony/lib/nimonyplugins

# Valid construction: CallX with an ExprChild
var child = createTree()
child.addIdent "foo"

var t = createTree(CallX, child)
doAssert not t.isEmpty

echo "C06_C32: PASS"
