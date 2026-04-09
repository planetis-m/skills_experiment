# Test C23, C24: struct layout and fixed arrays
import std/assertions

# C24: fixed-size array in struct maps to array[N, T]
type
  Color {.packed.} = object
    rgba: array[4, uint8]

static: doAssert sizeof(Color) == 4

# C23: object fields in C order; packed only if C specifies
type
  NormalStruct = object
    a: cint
    b: cint

static: doAssert sizeof(NormalStruct) == 8
static: doAssert offsetOf(NormalStruct, a) == 0
static: doAssert offsetOf(NormalStruct, b) == 4

echo "C23_C24: PASS"
