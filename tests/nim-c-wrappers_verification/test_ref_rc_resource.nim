# Test: rc_resource.md reference compiles and works
# Simulated C API using alloc/dealloc
{.push checks: off.}
type
  RawAsset = object
    data: cint

proc libLoad(path: cstring): ptr RawAsset =
  result = cast[ptr RawAsset](alloc0(sizeof(RawAsset)))
  result.data = 42

proc libFreeAsset(p: ptr RawAsset) =
  if p != nil: dealloc(p)

type
  Asset = object
    raw: ptr RawAsset
    rc: ptr int

proc `=destroy`(a: Asset) =
  if a.raw != nil:
    if a.rc[] == 0:
      libFreeAsset(a.raw)
      dealloc(a.rc)
    else:
      dec a.rc[]

proc `=wasMoved`(a: var Asset) =
  a.raw = nil
  a.rc = nil

proc `=sink`(dest: var Asset; src: Asset) =
  `=destroy`(dest)
  dest.raw = src.raw
  dest.rc = src.rc

proc `=copy`(dest: var Asset; src: Asset) =
  if src.raw != nil: inc src.rc[]
  `=destroy`(dest)
  dest.raw = src.raw
  dest.rc = src.rc

proc `=dup`(src: Asset): Asset =
  result.raw = src.raw
  result.rc = src.rc
  if result.raw != nil:
    inc result.rc[]

proc loadAsset(path: string): Asset =
  let raw = libLoad(path.cstring)
  if raw == nil:
    raise newException(IOError, "Failed to load asset: " & path)
  result = Asset(
    raw: raw,
    rc: cast[ptr int](alloc0(sizeof(int))))
{.pop.}

proc share(a: Asset): Asset = a

proc main =
  var a = loadAsset("test.dat")
  doAssert a.raw != nil
  doAssert a.raw.data == 42
  doAssert a.rc[] == 0

  # =copy via proc return creates a shared reference
  var b = share(a)
  doAssert b.raw.data == 42
  doAssert a.rc[] == 1
  doAssert b.rc[] == 1

  # Move transfers ownership without incrementing
  var c = ensureMove(a)
  doAssert c.raw != nil
  doAssert c.rc[] == 1  # still shared between b and c

  # b destroyed: decrements rc from 1 to 0
  # c destroyed: rc == 0, frees raw and rc
main()

echo "ref_rc_resource: PASS"
