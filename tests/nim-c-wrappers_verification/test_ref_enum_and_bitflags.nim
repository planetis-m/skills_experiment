# Test: enum_and_bitflags.md reference compiles and works
# All enum + bitflags operators and procs from the reference

# --- Enum-like values ---
type
  LibMode = distinct cint

const
  LIB_ModeA = LibMode(0)
  LIB_ModeB = LibMode(2)
  LIB_ModeC = LibMode(3)

proc `==`(a, b: LibMode): bool {.borrow.}

# --- Bitflags ---
type
  LibFlags = distinct cuint

const
  LIB_FLAG_READ = LibFlags(1'u32 shl 0)
  LIB_FLAG_WRITE = LibFlags(1'u32 shl 1)
  LIB_FLAG_EXEC = LibFlags(1'u32 shl 2)

proc `==`(a, b: LibFlags): bool {.borrow.}

proc `+`(a, b: LibFlags): LibFlags {.inline.} =
  LibFlags(cuint(a) or cuint(b))

proc `-`(a, b: LibFlags): LibFlags {.inline.} =
  LibFlags(cuint(a) and not cuint(b))

proc `*`(a, b: LibFlags): LibFlags {.inline.} =
  LibFlags(cuint(a) and cuint(b))

proc `<=`(a, b: LibFlags): bool {.inline.} =
  (cuint(a) and not cuint(b)) == 0

proc contains(flags: LibFlags; flag: LibFlags): bool {.inline.} =
  (cuint(flags) and cuint(flag)) != 0

proc incl(a: var LibFlags; flag: LibFlags) {.inline.} =
  a = LibFlags(cuint(a) or cuint(flag))

proc excl(a: var LibFlags; flag: LibFlags) {.inline.} =
  a = LibFlags(cuint(a) and not cuint(flag))

proc main =
  # Enum-like
  doAssert LIB_ModeA == LIB_ModeA
  doAssert not (LIB_ModeA == LIB_ModeB)
  var m = LIB_ModeB
  doAssert m == LibMode(2)

  # Bitflag combine
  var flags = LIB_FLAG_READ + LIB_FLAG_WRITE
  doAssert contains(flags, LIB_FLAG_READ)
  doAssert contains(flags, LIB_FLAG_WRITE)
  doAssert not contains(flags, LIB_FLAG_EXEC)

  # Remove
  flags = flags - LIB_FLAG_WRITE
  doAssert not contains(flags, LIB_FLAG_WRITE)
  doAssert contains(flags, LIB_FLAG_READ)

  # Intersect
  let both = LIB_FLAG_READ + LIB_FLAG_EXEC
  let overlap = both * LIB_FLAG_READ
  doAssert contains(overlap, LIB_FLAG_READ)
  doAssert not contains(overlap, LIB_FLAG_EXEC)

  # Subset check
  doAssert LIB_FLAG_READ <= (LIB_FLAG_READ + LIB_FLAG_WRITE)
  doAssert not ((LIB_FLAG_READ + LIB_FLAG_EXEC) <= LIB_FLAG_READ)

  # Mutating incl/excl
  var f = LibFlags(0)
  f.incl(LIB_FLAG_READ)
  doAssert contains(f, LIB_FLAG_READ)
  f.excl(LIB_FLAG_READ)
  doAssert not contains(f, LIB_FLAG_READ)
main()

echo "ref_enum_bitflags: PASS"
