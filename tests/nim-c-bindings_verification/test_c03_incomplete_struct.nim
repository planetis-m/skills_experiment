# Test C03: incompleteStruct for partial/opaque C structs
# With incompleteStruct, Nim only uses the type as a pointer and doesn't need full layout
{.push header: "c03_partial.h".}
type
  PartialStruct {.incompleteStruct, importc: "struct PartialStruct".} = object
{.pop.}

var a: ptr PartialStruct = nil
discard a

echo "C03: PASS"
