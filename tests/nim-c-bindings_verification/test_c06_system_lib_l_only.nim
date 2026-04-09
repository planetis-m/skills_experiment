# Test C06: system libraries link with `-l<name>` only.
import std/math

when defined(linux):
  {.passL: "-lm".}

proc cosC(x: cdouble): cdouble {.importc: "cos", cdecl, header: "<math.h>".}

when defined(linux):
  doAssert abs(cosC(0.0) - 1.0) < 1e-12

echo "C06: PASS"
