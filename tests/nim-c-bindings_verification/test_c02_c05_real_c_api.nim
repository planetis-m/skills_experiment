# Test C02 expanded: opaque handle via importc with a real C type
# Also verifies C05 (header pragma)
proc fopen(pathname: cstring; mode: cstring): pointer {.importc: "fopen", cdecl, header: "<stdio.h>".}
proc fclose(stream: pointer): cint {.importc: "fclose", cdecl, header: "<stdio.h>".}

# fopen returns an opaque FILE* — we represent it as pointer
var f = fopen("/dev/null".cstring, "r".cstring)
if f != nil:
  discard fclose(f)

echo "C02_C05_real: PASS"
