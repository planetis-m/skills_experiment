# Test C19: eqIdent exact-name check
import nimony/lib/nimonyplugins

var t = createTree()
t.addIdent "myName"
var n = snapshot(t)
doAssert n.eqIdent("myName")
doAssert not n.eqIdent("otherName")

echo "C19: PASS"
