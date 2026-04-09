# Test C36: seq reallocation risk with C pointers
# Demonstrates that getting a ptr into seq and then appending invalidates the pointer
var s: seq[cint] = @[1.cint, 2.cint, 3.cint]
let p = addr s[0]
let oldP = cast[int](p)
s.add(4.cint)  # may reallocate
let newP = cast[int](addr s[0])
# After add, the address may have changed (reallocation)
# This demonstrates the risk - not always fails but shows the pattern
discard oldP
discard newP

echo "C36: PASS"
