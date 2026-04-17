# Test: move_only_resource.md reference compiles and works
# Simulated C API using alloc/dealloc instead of real importc
{.push checks: off.}
type
  RawHandle = object
    w: cint
    h: cint

proc libCreate(width, height: cint): ptr RawHandle =
  result = cast[ptr RawHandle](alloc0(sizeof(RawHandle)))
  result.w = width
  result.h = height

proc libDestroy(h: ptr RawHandle) =
  if h != nil: dealloc(h)

type
  Handle = object
    raw: ptr RawHandle

proc `=destroy`(h: Handle) =
  if h.raw != nil:
    libDestroy(h.raw)

proc `=wasMoved`(h: var Handle) =
  h.raw = nil

proc `=sink`(dest: var Handle; src: Handle) =
  `=destroy`(dest)
  dest.raw = src.raw

proc `=copy`(dest: var Handle; src: Handle) {.error.}
proc `=dup`(src: Handle): Handle {.error.}
{.pop.}

proc initHandle(width, height: int): Handle =
  result.raw = libCreate(cint(width), cint(height))
  if result.raw == nil:
    raise newException(ValueError, "Failed to create handle")

proc main =
  var a = initHandle(640, 480)

  # ensureMove transfers ownership
  var b = ensureMove(a)
  doAssert b.raw != nil
  doAssert b.raw.w == 640
  doAssert b.raw.h == 480

  # b is cleaned up by =destroy
main()

echo "ref_move_only: PASS"
