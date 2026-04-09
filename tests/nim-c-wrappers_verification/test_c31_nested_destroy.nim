# Test C31: custom =destroy does not automatically destroy nested destructor-managed fields.
var nestedDrops = 0
var rawDrops = 0

type
  Nested = object

proc `=destroy`(x: Nested) =
  discard x
  inc nestedDrops

type
  BadWrapper = object
    raw: pointer
    nested: Nested

  GoodWrapper = object
    raw: pointer
    nested: Nested

proc `=destroy`(x: BadWrapper) =
  if x.raw != nil:
    inc rawDrops

proc `=destroy`(x: GoodWrapper) =
  if x.raw != nil:
    inc rawDrops
  `=destroy`(x.nested)

proc makeBad() =
  var x = BadWrapper(raw: cast[pointer](1))
  discard x

proc makeGood() =
  var x = GoodWrapper(raw: cast[pointer](1))
  discard x

nestedDrops = 0
rawDrops = 0
makeBad()
doAssert rawDrops == 1
doAssert nestedDrops == 0

nestedDrops = 0
rawDrops = 0
makeGood()
doAssert rawDrops == 1
doAssert nestedDrops == 1

echo "C31: PASS"
