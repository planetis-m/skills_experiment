# Test C29 negative: {.error.} on =copy should prevent compilation
type
  RawHandle = object
  Handle = object
    raw: ptr RawHandle

proc `=destroy`(h: Handle) =
  if h.raw != nil: dealloc(h.raw)

proc `=wasMoved`(h: var Handle) = h.raw = nil
proc `=sink`(dest: var Handle; src: Handle) =
  `=destroy`(dest)
  dest.raw = src.raw

proc `=copy`(dest: var Handle; src: Handle) {.error.}

proc makeHandle(): Handle =
  result.raw = cast[ptr RawHandle](alloc0(sizeof(RawHandle)))

var a = makeHandle()
var b = a  # should fail: =copy is {.error.}
