# Test C39, C40: ptr T + csize_t pattern; ptr UncheckedArray[T]
type
  Buffer = ptr UncheckedArray[byte]

proc readInto(buf: ptr byte; len: csize_t): cint =
  discard
  result = 0

var data: array[64, byte]
discard readInto(addr data[0], csize_t(data.len))

var ubuf: Buffer = cast[Buffer](alloc0(64))
dealloc(ubuf)

echo "C39_C40: PASS"
