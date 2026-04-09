# Test integer type size claims C17, C19, C20, C42-C45
import std/assertions

# C42: signed char -> cschar (always int8)
static: doAssert sizeof(cschar) == 1
static: doAssert int8(cschar(42)) == 42

# C17: char -> cchar
static: doAssert sizeof(cchar) == 1

# C43: short -> cshort (int16), unsigned short -> cushort (uint16)
static: doAssert sizeof(cshort) == 2
static: doAssert sizeof(cushort) == 2

# C44: int -> cint (int32), unsigned int -> cuint (uint32)
static: doAssert sizeof(cint) == 4
static: doAssert sizeof(cuint) == 4

# C19: long -> clong (ABI-sized: int32 on Windows, int on LP64)
when defined(windows):
  static: doAssert sizeof(clong) == 4
else:
  static: doAssert sizeof(clong) == sizeof(int)

# C45: long long -> clonglong (int64), unsigned long long -> culonglong (uint64)
static: doAssert sizeof(clonglong) == 8
static: doAssert sizeof(culonglong) == 8

# C20: size_t -> csize_t (alias for uint, ABI-sized)
static: doAssert sizeof(csize_t) == sizeof(uint)

# C38: intptr_t -> int (pointer-sized signed), uintptr_t -> uint (pointer-sized unsigned)
static: doAssert sizeof(int) == sizeof(pointer)
static: doAssert sizeof(uint) == sizeof(pointer)

echo "C17_C19_C20_C42_C43_C44_C45_C38: PASS"
