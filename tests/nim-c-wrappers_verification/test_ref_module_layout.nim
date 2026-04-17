# Test: module_layout.md reference compiles and works
# Multi-module layout test — raw types, raw bindings, ergonomic wrapper

# -- Simulated raw types module (inline for self-contained test) --
when defined(windows):
  const fooDll = "foo.dll"
elif defined(macosx):
  const fooDll = "libfoo(.3|.1|).dylib"
else:
  const fooDll = "libfoo.so(.3|.1|)"

type
  Color {.bycopy.} = object
    r*, g*, b*, a*: uint8

  Rect {.bycopy.} = object
    x*, y*, width*, height*: float32

  Texture {.bycopy.} = object
    id*: uint32
    width*: int32
    height*: int32

  PixelFormat = distinct cint

proc `==`(a, b: PixelFormat): bool {.borrow.}

const
  FormatUncompressedR8g8b8a8 = PixelFormat(1)

# Simulated C functions (no real dynlib, just matching signatures)
proc libLoadTexture(path: cstring): Texture =
  result.id = 1
  result.width = 64
  result.height = 64

proc libUnloadTexture(texture: Texture) =
  discard

proc libDrawTexture(texture: Texture; source, dest: Rect; color: Color) =
  discard

# -- Ergonomic wrapper layer --
proc `=destroy`(t: var Texture) =
  libUnloadTexture(t)

proc `=wasMoved`(x: var Texture) =
  x.id = 0

proc `=dup`(src: Texture): Texture {.error.}
proc `=copy`(dest: var Texture; src: Texture) {.error.}

proc loadTexture(path: string): Texture =
  result = libLoadTexture(path.cstring)
  if result.id == 0:
    raise newException(IOError, "Failed to load texture: " & path)

proc drawTexture(texture: Texture; src, dest: Rect; tint: Color) {.inline.} =
  libDrawTexture(texture, src, dest, tint)

proc main =
  # Raw types are accessible
  doAssert sizeof(Color) == 4
  doAssert sizeof(Rect) == 16
  doAssert sizeof(Texture) == 12

  # PixelFormat is distinct cint
  doAssert FormatUncompressedR8g8b8a8 == PixelFormat(1)

  # Ergonomic wrapper
  var tex = loadTexture("test.png")

  # Move ownership
  var tex2 = ensureMove(tex)
  doAssert tex2.id == 1
  doAssert tex2.width == 64

  # Draw with it
  let srcRect = Rect(x: 0, y: 0, width: 64, height: 64)
  let dstRect = Rect(x: 10, y: 10, width: 64, height: 64)
  let tint = Color(r: 255, g: 255, b: 255, a: 255)
  drawTexture(tex2, srcRect, dstRect, tint)
main()

echo "ref_module_layout: PASS"
