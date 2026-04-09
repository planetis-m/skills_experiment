# Test C10: inc advances one token, skip skips whole subtree
import nimony/lib/nimonyplugins

var t = createTree()
t.withTree(CallX, NoLineInfo):
  t.addIdent "echo"
  t.addStrLit "hello"

var n = snapshot(t)
doAssert n.exprKind == CallX
inc n  # past ParLe into first child
doAssert n.kind == Ident  # "echo"
inc n  # past Ident
doAssert n.kind == StringLit  # "hello"
inc n  # past StringLit
doAssert n.kind == ParRi

# Now test skip on a fresh tree with nested structure
var t2 = createTree()
t2.withTree(StmtsS, NoLineInfo):
  t2.withTree(CallX, NoLineInfo):
    t2.addIdent "foo"
  t2.withTree(CallX, NoLineInfo):
    t2.addIdent "bar"

var n2 = snapshot(t2)
doAssert n2.stmtKind == StmtsS
inc n2  # past StmtsS ParLe
# now at first CallX child
doAssert n2.exprKind == CallX
skip n2  # skips entire CallX subtree
# now at second CallX
doAssert n2.exprKind == CallX
skip n2
doAssert n2.kind == ParRi  # end of StmtsS

echo "C10: PASS"
