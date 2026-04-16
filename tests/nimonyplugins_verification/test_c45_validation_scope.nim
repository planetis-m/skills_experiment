# Test C45: Validation scope - createTree(kind,...), %~, and nifFragment
# validate structure; manual withTree does NOT validate.
import nimony/lib/nimonyplugins
import std/strutils

# createTree with wrong shape → ErrT (validated)
var badCall = createTree(CallX)
var badNode = snapshot(badCall)
doAssert $badNode.tag == $ErrT

# nifFragment with wrong shape → ErrT (validated)
var badFrag = nifFragment("(call)")
var badFragNode = snapshot(badFrag)
doAssert $badFragNode.tag == $ErrT

# Manual withTree with no callee → NOT validated, stays as-is
var manual = createTree()
manual.withTree(CallX, NoLineInfo):
  discard
var manualNode = snapshot(manual)
doAssert $manualNode.exprKind == $CallX
doAssert not renderNode(manualNode).contains("ErrT")

echo "C45: PASS"
