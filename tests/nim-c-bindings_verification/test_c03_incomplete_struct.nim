## C03: incompleteStruct for partial and opaque imported C structs

import std/os

const testDir = currentSourcePath.parentDir
const headerPath = testDir / "c03_partial.h"

type
  PartialStruct {.importc: "struct PartialStruct", header: headerPath,
                  incompleteStruct.} = object
    x: cint

  OpaqueStruct {.importc: "struct OpaqueOnly", header: headerPath,
                 incompleteStruct.} = object

proc newPartialStruct(x, y: cint): ptr PartialStruct
  {.importc: "c03_new_partial_struct", header: headerPath.}
proc sumPartialStruct(p: ptr PartialStruct): cint
  {.importc: "c03_sum_partial_struct", header: headerPath.}
proc isNullOpaque(p: ptr OpaqueStruct): cint
  {.importc: "c03_is_null_opaque", header: headerPath.}
proc freePartialStruct(p: ptr PartialStruct)
  {.importc: "c03_free_partial_struct", header: headerPath.}

block partial_prefix_struct:
  let p = newPartialStruct(10, 32)
  doAssert p != nil, "partial struct helper should allocate"
  doAssert p[].x == 10, "known prefix field should be readable from Nim"
  doAssert sumPartialStruct(p) == 42, "C should still see the full underlying layout"
  freePartialStruct(p)

block opaque_pointer_only:
  var p: ptr OpaqueStruct = nil
  doAssert p.isNil, "opaque imported struct should still be usable through pointers"
  doAssert isNullOpaque(p) == 1, "opaque pointer should round-trip through a C API"

static:
  doAssert compiles(block:
    var p: ptr PartialStruct = nil
    discard p[].x),
    "known prefix fields on a partial imported struct should be usable"

  doAssert compiles(block:
    var p: ptr OpaqueStruct = nil
    discard p),
    "opaque imported structs should still be usable through pointers"

  doAssert not compiles(block:
    var p: ptr OpaqueStruct = nil
    discard p[].x),
    "opaque imported structs should not expose fields"

  doAssert not compiles(block:
    const s = sizeof(OpaqueStruct)
    s),
    "sizeof on an incompleteStruct type should fail to compile"

echo "C03: PASS"
