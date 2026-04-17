# Test: custom_sink.md reference compiles and works
type
  Child = object
    data: ptr UncheckedArray[int]
    len: int

proc `=destroy`(c: Child) =
  if c.data != nil:
    dealloc(c.data)

proc `=wasMoved`(c: var Child) =
  c.data = nil
  c.len = 0

proc `=dup`(src: Child): Child {.nodestroy.} =
  result = Child(len: src.len, data: nil)
  if src.data != nil and src.len > 0:
    result.data = cast[ptr UncheckedArray[int]](alloc(src.len * sizeof(int)))
    copyMem(result.data, src.data, src.len * sizeof(int))

type
  T = object
    field: Child

proc `=sink`*(dest: var T; src: T) =
  `=destroy`(dest)
  `=wasMoved`(dest)
  dest.field = src.field

proc initT(vals: openArray[int]): T =
  result.field = Child(len: vals.len, data: nil)
  if vals.len > 0:
    result.field.data = cast[ptr UncheckedArray[int]](alloc(vals.len * sizeof(int)))
    for i in 0..<vals.len:
      result.field.data[i] = vals[i]

proc main =
  var a = initT([42])
  var b = ensureMove(a)
  doAssert b.field.data[0] == 42

main()
echo "ref_custom_sink: PASS"
