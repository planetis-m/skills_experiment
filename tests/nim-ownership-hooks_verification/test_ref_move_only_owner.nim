# Test: move_only_owner.md reference compiles and works
type
  Buffer = object
    data: ptr UncheckedArray[int]
    len: int

proc `=destroy`*(x: Buffer) =
  if x.data != nil:
    dealloc(x.data)

proc `=wasMoved`*(x: var Buffer) =
  x.data = nil

proc `=copy`*(dest: var Buffer; src: Buffer) {.error.}

proc initBuffer(items: openArray[int]): Buffer =
  result = Buffer(len: items.len, data: nil)
  if items.len > 0:
    result.data = cast[ptr UncheckedArray[int]](alloc(items.len * sizeof(int)))
    for i in 0..<items.len:
      result.data[i] = items[i]

proc main =
  var a = initBuffer([1, 2, 3])
  var b = ensureMove(a)
  doAssert b.len == 3
  doAssert b.data[0] == 1
  doAssert b.data[2] == 3

  var c = initBuffer([])
  var d = ensureMove(c)
  doAssert d.len == 0
  doAssert d.data == nil

main()
echo "ref_move_only_owner: PASS"
