# Test C46: $$ in NIF template produces a literal dollar sign
import nimony/lib/nimonyplugins
import std/strutils

var t = nifFragment("(stmts $$)")
var rendered = renderTree(t)
doAssert "$" in rendered

# $$ just escapes $, and $name still substitutes
var t2 = `%~`("(ident $$name)", [("name", ~ident("x"))])
var rendered2 = renderTree(t2)
doAssert "$" in rendered2

echo "C46: PASS"
