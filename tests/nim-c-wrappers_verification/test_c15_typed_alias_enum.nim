# Test C15: raw bindings should use typed integer aliases + const, not Nim enum
# Demonstrate that typed alias + const works
type LibMode = cint
const
  LIB_ModeA = LibMode(0)
  LIB_ModeB = LibMode(2)
  LIB_ModeC = LibMode(3)

var m: LibMode = LIB_ModeA
doAssert m == LibMode(0)
m = LIB_ModeB
doAssert m == LibMode(2)

echo "C15: PASS"
