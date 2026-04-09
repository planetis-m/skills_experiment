# Test C35: string vs cstring type mismatch
# Demonstrates that Nim string cannot be passed where cstring is expected without .cstring
proc takesCstring(s: cstring): cint = 0

var s: string = "hello"
# This should work with .cstring:
discard takesCstring(s.cstring)
# And cstring is a different type than string:
static: doAssert typeof("hello") is string
static: doAssert typeof("hello".cstring) is cstring

echo "C35: PASS"
