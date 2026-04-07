# Test C35: In =copy for deep-owning containers, after destroy + wasMoved,
# check that source data is non-nil before allocating and copying.

type
  Buffer = object
    data: ptr int
    len: int

proc `=destroy`*(x: Buffer) =
  if x.data != nil:
    dealloc(x.data)

proc `=wasMoved`*(x: var Buffer) =
  x.data = nil
  x.len = 0

proc `=dup`*(x: Buffer): Buffer {.nodestroy.} =
  result = Buffer(len: x.len, data: nil)
  if x.data != nil and x.len > 0:
    result.data = cast[ptr int](alloc(x.len * sizeof(int)))
    copyMem(result.data, x.data, x.len * sizeof(int))

proc `=copy`*(dest: var Buffer; src: Buffer) =
  if dest.data == src.data: return
  `=destroy`(dest)
  `=wasMoved`(dest)
  dest.len = src.len
  if src.data != nil and src.len > 0:
    dest.data = cast[ptr int](alloc(src.len * sizeof(int)))
    copyMem(dest.data, src.data, src.len * sizeof(int))

proc initBuffer(items: openArray[int]): Buffer =
  result = Buffer(len: items.len, data: nil)
  if items.len > 0:
    result.data = cast[ptr int](alloc(items.len * sizeof(int)))
    for i in 0..<items.len:
      (cast[ptr UncheckedArray[int]](result.data))[i] = items[i]

proc test() =
  # Copy from empty buffer
  var a = initBuffer([])
  doAssert a.data == nil
  doAssert a.len == 0

  var b = initBuffer([1, 2, 3])
  doAssert b.data != nil
  doAssert b.len == 3

  # Copy empty into non-empty
  b = a  # =copy: dest has data, src is empty
  doAssert b.data == nil
  doAssert b.len == 0

  # Copy non-empty into empty
  var c = initBuffer([10, 20])
  a = c  # =copy: dest is empty, src has data
  doAssert a.data != nil
  doAssert a.len == 2
  doAssert (cast[ptr UncheckedArray[int]](a.data))[0] == 10
  doAssert (cast[ptr UncheckedArray[int]](a.data))[1] == 20

  echo "C35: PASS"

test()
