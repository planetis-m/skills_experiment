# Test floating-point type claims C46, C21
import std/assertions

# C46: float -> cfloat (float32), double -> cdouble (float64)
static: doAssert sizeof(cfloat) == 4
static: doAssert sizeof(cdouble) == 8

# C21: clongdouble exists but is not truly supported by codegen
# We can verify it exists and has a size, but note the limitation
static: doAssert sizeof(clongdouble) >= 8  # at least as big as double, often 12 or 16

echo "C46_C21: PASS"
