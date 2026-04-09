# Test C18: errorTree variants
import nimony/lib/nimonyplugins

# errorTree(msg) - synthetic
var e1 = errorTree("test error")
doAssert not e1.isEmpty

# errorTree(msg, at) - with source location
var src = createTree()
src.withTree(CallX, NoLineInfo):
  src.addIdent "foo"
var n = snapshot(src)
var e2 = errorTree("bad call", n)
doAssert not e2.isEmpty

echo "C18: PASS"
