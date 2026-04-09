# Test C29: move-only resource with =destroy, =wasMoved, =sink; =copy/=dup {.error.}
{.push checks: off.}
type
  RawHandle = object
  Handle = object
    raw: ptr RawHandle

proc `=destroy`(h: Handle) =
  if h.raw != nil:
    dealloc(h.raw)

proc `=wasMoved`(h: var Handle) =
  h.raw = nil

proc `=sink`(dest: var Handle; src: Handle) =
  `=destroy`(dest)
  dest.raw = src.raw

proc `=copy`(dest: var Handle; src: Handle) {.error.}
proc `=dup`(src: Handle): Handle {.error.}
{.pop.}

proc makeHandle(): Handle =
  result.raw = cast[ptr RawHandle](alloc0(sizeof(RawHandle)))

proc main =
  var a = makeHandle()
  var b = ensureMove(a)
  # a is now moved-out, b owns the resource
  doAssert b.raw != nil

main()

echo "C29: PASS"
