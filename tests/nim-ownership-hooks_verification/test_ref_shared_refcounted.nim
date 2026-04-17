# Test: shared_refcounted.md reference compiles and works (separate counter pattern)
# Uses the inverted counter: 0 = exclusive, >0 = shared
type
  Obj = object
    val: int

proc createObj(v: int): ptr Obj =
  result = cast[ptr Obj](alloc0(sizeof(Obj)))
  result.val = v

proc destroyObj(p: ptr Obj) =
  if p != nil: dealloc(p)

type
  Wrapper = object
    obj: ptr Obj
    rc: ptr int

proc `=destroy`*(dest: Wrapper) =
  if dest.obj != nil:
    if dest.rc[] == 0:
      dealloc(dest.rc)
      destroyObj(dest.obj)
    else:
      dec dest.rc[]

proc `=wasMoved`*(dest: var Wrapper) =
  dest.obj = nil
  dest.rc = nil

proc `=dup`*(src: Wrapper): Wrapper =
  if src.obj != nil: inc src.rc[]
  result.obj = src.obj
  result.rc = src.rc

proc `=copy`*(dest: var Wrapper; src: Wrapper) =
  if src.obj != nil: inc src.rc[]
  `=destroy`(dest)
  dest.obj = src.obj
  dest.rc = src.rc

proc create(val: int): Wrapper =
  Wrapper(obj: createObj(val),
          rc: cast[ptr int](alloc0(sizeof(int))))

proc share(w: Wrapper): Wrapper = w

proc main =
  var a = create(42)
  doAssert a.rc[] == 0

  # Share via proc return (=dup)
  var b = share(a)
  doAssert b.obj == a.obj
  doAssert a.rc[] == 1
  doAssert b.rc[] == 1

  # Move
  var c = ensureMove(a)
  doAssert c.rc[] == 1

  # Destroy b: rc 1 -> 0
  # Destroy c: rc == 0, frees obj and rc
main()
echo "ref_shared_refcounted: PASS"
