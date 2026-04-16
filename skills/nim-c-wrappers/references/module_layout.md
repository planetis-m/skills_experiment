# Module Layout

```
libname/
├── bindings/
│   └── libname_raw.nim  # Raw FFI — importc procs, C types, constants only
└── libname.nim          # Ergonomic wrapper
```

```nim
# bindings/libname_raw.nim
when defined(windows):
  const libDll = "libname.dll"
elif defined(macosx):
  const libDll = "liblibname.dylib"
else:
  const libDll = "liblibname.so"

{.pragma: importLib, cdecl, dynlib: libDll.}

type
  Color* {.bycopy.} = object
    r*, g*, b*, a*: uint8

  Rect* {.bycopy.} = object
    x*, y*, width*, height*: float32

  Texture* {.bycopy.} = object
    id*: uint32
    width*: int32
    height*: int32

  PixelFormat* = distinct cint

const
  FormatUncompressedR8g8b8a8* = PixelFormat(1)

proc libLoadTexture*(path: cstring): Texture {.importc: "lib_load_texture", importLib.}
proc libUnloadTexture*(texture: Texture) {.importc: "lib_unload_texture", importLib.}
proc libDrawTexture*(texture: Texture; source, dest: Rect; color: Color) {.importc: "lib_draw_texture", importLib.}
```

```nim
# libname.nim
import ./bindings/libname_raw
export libname_raw

proc `=destroy`*(t: Texture) =
  libUnloadTexture(t)
proc `=wasMoved`*(x: var Texture) =
  x.id = 0
proc `=dup`*(src: Texture): Texture {.error.}
proc `=copy`*(dest: var Texture; src: Texture) {.error.}

proc loadTexture*(path: string): Texture =
  result = libLoadTexture(path.cstring)
  if result.id == 0:
    raise newException(IOError, "Failed to load texture: " & path)

proc drawTexture*(texture: Texture; src, dest: Rect; tint: Color) =
  libDrawTexture(texture, src, dest, tint)
```

## Rules

- Raw module: `importc` procs, C types, constants only. No Nim logic.
- Wrapper imports raw with `import` + `export` — gives downstream access to both layers.
- Wrapper imports from raw — never the reverse.
- Wrapper uses Nim types (`float`, `int`, `string`) in its public API. Convert to C types at the call boundary.
- Thin wrappers where the C API is already the public API: skip the split, use a single flat module.
- Avoid `from ... import nil` — it forces every type and proc through a module qualifier, adding noise with no real benefit.
