# Test C32: reference-counted resource pattern compiles and basic operations work
{.push checks: off.}
type
  RawAsset = object
    data: cint

proc libFreeAsset(p: ptr RawAsset) = dealloc(p)

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

proc loadAsset(): Asset =
  Asset(raw: cast[ptr RawAsset](alloc0(sizeof(RawAsset))),
        rc: cast[ptr int](alloc0(sizeof(int))))
{.pop.}

proc main =
  var a = loadAsset()
  doAssert a.raw != nil
  doAssert a.rc[] == 0
  # Move semantics work
  var c = ensureMove(a)
  doAssert c.raw != nil
  doAssert c.rc[] == 0

main()

echo "C32: PASS"
