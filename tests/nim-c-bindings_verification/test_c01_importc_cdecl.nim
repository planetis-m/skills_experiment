# Test C01: importc with cdecl for C APIs
proc malloc(size: csize_t): pointer {.importc: "malloc", cdecl, header: "<stdlib.h>".}
proc free(p: pointer) {.importc: "free", cdecl, header: "<stdlib.h>".}

var p = malloc(64)
doAssert p != nil
free(p)

echo "C01: PASS"
