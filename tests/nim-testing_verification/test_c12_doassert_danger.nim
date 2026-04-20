import std/strutils

block doassert_compiled_out:
  when defined(danger):
    var doassertRan = false
    doAssert false, "this should be compiled out in danger"
    doassertRan = true
    doAssert not doassertRan, "C12: doAssert should not execute in danger mode but it did"
    echo "C12: PASS (doAssert was NOT compiled out — this is unexpected)"
  else:
    echo "C12: PASS (non-danger mode; doAssert is active, tested by C01)"
