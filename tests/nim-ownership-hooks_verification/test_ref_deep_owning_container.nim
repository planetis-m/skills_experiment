# Test: deep_owning_container.md reference compiles and works
type
  Container = object
    data: ptr UncheckedArray[int]
    len: int

proc `=destroy`*(x: Container) =
  if x.data != nil:
    dealloc(x.data)

proc `=wasMoved`*(x: var Container) =
  x.data = nil
  x.len = 0

proc `=dup`*(src: Container): Container {.nodestroy.} =
  result = Container(len: src.len, data: nil)
  if src.data != nil and src.len > 0:
    result.data = cast[ptr UncheckedArray[int]](alloc(src.len * sizeof(int)))
    copyMem(result.data, src.data, src.len * sizeof(int))

proc `=copy`*(dest: var Container; src: Container) =
  if dest.data == src.data: return
  `=destroy`(dest)
  `=wasMoved`(dest)
  dest.len = src.len
  if src.data != nil and src.len > 0:
    dest.data = cast[ptr UncheckedArray[int]](alloc(src.len * sizeof(int)))
    copyMem(dest.data, src.data, src.len * sizeof(int))

proc initContainer(items: openArray[int]): Container =
  result = Container(len: items.len, data: nil)
  if items.len > 0:
    result.data = cast[ptr UncheckedArray[int]](alloc(items.len * sizeof(int)))
    for i in 0..<items.len:
      result.data[i] = items[i]

proc share(c: Container): Container = c

proc main =
  var c = initContainer([10, 20, 30])
  doAssert c.len == 3
  doAssert c.data[0] == 10
  doAssert c.data[2] == 30

  # Deep copy via =dup
  var d = share(c)
  doAssert d.len == 3
  doAssert d.data != c.data
  d.data[1] = 99
  doAssert c.data[1] == 20
  doAssert d.data[1] == 99

  # Empty container
  var e = initContainer([])
  doAssert e.len == 0
  doAssert e.data == nil

main()
echo "ref_deep_owning_container: PASS"
