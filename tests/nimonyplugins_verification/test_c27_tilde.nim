# Test C27: ~ operator conversions
import nimony/lib/nimonyplugins

# ~string → strLit
var s = ~"hello"
doAssert not s.isEmpty

# ~int → intLit
var i = ~42
doAssert not i.isEmpty

# ~bool → true/false
var b = ~true
doAssert not b.isEmpty

# ~char → charLit
var c = ~'x'
doAssert not c.isEmpty

# ~Tree → identity
var inner = createTree()
inner.addIdent "test"
var same = ~inner
doAssert not same.isEmpty

echo "C27: PASS"
