# Test C22, C24: NifBuilder copy-on-write - mutations detach
import nimony/lib/nimonyplugins

var t1 = createTree()
t1.addIdent "original"

var t2 = t1  # copy shares payload
t2.addIdent "mutated"

# t1 should NOT see the mutation (COW detaches)
doAssert not t1.isEmpty
doAssert not t2.isEmpty
# Both should have content but different
doAssert renderTree(t1) != renderTree(t2)

echo "C22_C24: PASS"
