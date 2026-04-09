# Test C05: header pragma for C definitions
# Using header with real C stdlib functions
proc cMalloc(size: csize_t): pointer {.importc: "malloc", header: "<stdlib.h>".}
proc cFree(p: pointer) {.importc: "free", header: "<stdlib.h>".}

var p = cMalloc(32)
doAssert p != nil
cFree(p)

echo "C05: PASS"
