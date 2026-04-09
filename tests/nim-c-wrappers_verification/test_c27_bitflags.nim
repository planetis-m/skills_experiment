# Test C27: bitflags with distinct integer + bitwise helpers, not set[Enum]
type LibFlags = distinct cuint

const
  LIB_FLAG_READ = LibFlags(1'u32 shl 0)
  LIB_FLAG_WRITE = LibFlags(1'u32 shl 1)

proc has(flags: LibFlags; flag: LibFlags): bool {.inline.} =
  (cuint(flags) and cuint(flag)) != 0'u32

var f = LibFlags(cuint(LIB_FLAG_READ) or cuint(LIB_FLAG_WRITE))
doAssert f.has(LIB_FLAG_READ)
doAssert f.has(LIB_FLAG_WRITE)
doAssert not LibFlags(0).has(LIB_FLAG_READ)

echo "C27: PASS"
