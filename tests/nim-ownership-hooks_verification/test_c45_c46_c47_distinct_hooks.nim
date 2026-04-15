type
  Buf = object
    p: ptr int

var bufDestroys = 0
var bufCopies = 0

proc `=destroy`*(x: Buf) =
  if x.p != nil:
    dealloc(x.p)
    inc bufDestroys

proc `=wasMoved`*(x: var Buf) =
  x.p = nil

proc `=copy`*(dest: var Buf; src: Buf) =
  if dest.p == src.p: return
  `=destroy`(dest)
  dest.p = cast[ptr int](alloc(sizeof(int)))
  dest.p[] = src.p[]
  inc bufCopies

type
  DNoHook = distinct Buf

block: # C45: distinct type with no custom hooks — base hooks fire through
  bufDestroys = 0
  bufCopies = 0
  var d1 = DNoHook(Buf(p: cast[ptr int](alloc(sizeof(int)))))
  d1 = DNoHook(Buf(p: cast[ptr int](alloc(sizeof(int)))))  # overwrite
  var d2 = d1  # copy
  discard d1
  discard d2

doAssert bufDestroys == 3, "base =destroy for overwrite + 2 scope exits, got " & $bufDestroys
doAssert bufCopies == 1, "base =copy for d2 = d1, got " & $bufCopies

type
  DCustomDestroy = distinct Buf

var customDestroys = 0

proc `=destroy`*(x: DCustomDestroy) =
  inc customDestroys
  `=destroy`(Buf(x))

block: # C46: distinct type can override =destroy but not =wasMoved, =copy, =dup
  customDestroys = 0
  bufDestroys = 0
  var d = DCustomDestroy(Buf(p: cast[ptr int](alloc(sizeof(int)))))
  discard d

doAssert customDestroys == 1, "custom =destroy fired, got " & $customDestroys
doAssert bufDestroys == 1, "delegated to base, got " & $bufDestroys

block: # C46b: =copy lifts from base, not overridable
  bufCopies = 0
  var d1 = DCustomDestroy(Buf(p: cast[ptr int](alloc(sizeof(int)))))
  var d2 = d1
  discard d1
  discard d2

doAssert bufCopies == 1, "base =copy lifted through distinct, got " & $bufCopies

type
  Fd = distinct int

var fdDestroys = 0

proc `=destroy`*(x: Fd) =
  if int(x) > 0:
    inc fdDestroys

block: # C47: distinct int can override =destroy; moved-from resets to 0
  fdDestroys = 0
  var d1 = Fd(5)
  var d2 = move(d1)
  discard d2
  doAssert int(d1) == 0, "moved-from distinct int resets to default (0)"

doAssert fdDestroys == 1, "custom =destroy for Fd fires on scope exit, got " & $fdDestroys

echo "C45_C46_C47: PASS"
