# Test C01: importc with cdecl for C APIs
static:
  doAssert compiles(block:
    proc mallocGood(size: csize_t): pointer
      {.importc: "malloc", cdecl, header: "<stdlib.h>".}),
    "`cdecl` should be accepted on imported C procs"

  doAssert not compiles(block:
    proc mallocBad(size: csize_t): pointer
      {.importc: "malloc", callconv: cdecl, header: "<stdlib.h>".}),
    "`callconv: cdecl` should not be used on individual proc declarations"

proc malloc(size: csize_t): pointer {.importc: "malloc", cdecl, header: "<stdlib.h>".}
proc free(p: pointer) {.importc: "free", cdecl, header: "<stdlib.h>".}

var p = malloc(64)
doAssert p != nil
free(p)

echo "C01: PASS"
