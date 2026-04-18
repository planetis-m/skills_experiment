# Test C29: nifFragment parses NIF text into NifBuilder
import nimony/lib/nimonyplugins

var t = nifFragment("(call echo \"hello\")")
doAssert not t.isEmpty

echo "C29: PASS"
