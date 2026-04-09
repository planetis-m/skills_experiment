# Test C11: {.push callconv: cdecl.} scoped pragma blocks compile correctly
# We test the pattern compiles by using importc with a real C function (e.g., malloc)
{.push callconv: cdecl.}
proc myMalloc(size: csize_t): pointer {.importc: "malloc", header: "<stdlib.h>".}
proc myFree(p: pointer) {.importc: "free", header: "<stdlib.h>".}
{.pop.}

var p = myMalloc(64)
doAssert p != nil
myFree(p)

echo "C11: PASS"
