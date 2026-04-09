# Test C11: takeTree advances, addSubtree does not
import nimony/lib/nimonyplugins

var src = createTree()
src.withTree(StmtsS, NoLineInfo):
  src.addIdent "a"
  src.addIdent "b"

var reader = snapshot(src)
inc reader  # past StmtsS ParLe

# addSubtree does not advance
var dest1 = createTree()
dest1.addSubtree(reader)
doAssert reader.identText == "a"  # still at "a"

# takeTree advances
var dest2 = createTree()
dest2.takeTree(reader)
doAssert reader.kind == Ident  # now at "b"

echo "C11: PASS"
