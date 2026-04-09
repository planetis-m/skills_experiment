# Test pointer/string type claims C47, C48, C22
import std/assertions

# C47: void* -> pointer, T* -> ptr T, T** -> ptr ptr T
var x: cint = 42
var p: ptr cint = addr x
var pp: ptr ptr cint = addr p
static: doAssert sizeof(pointer) == sizeof(uint)
discard pp

# C48: const char* -> cstring
var s: cstring = "hello"
static: doAssert typeof(s) is cstring
discard s

# C22: char** -> cstringArray = ptr UncheckedArray[cstring]
var arr = allocCStringArray(["a", "b"])
discard arr
deallocCStringArray(arr)

echo "C47_C48_C22: PASS"
