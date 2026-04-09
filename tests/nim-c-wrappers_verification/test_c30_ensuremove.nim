# Test C30: ensureMove vs move
type
  Obj = object
    data: int

proc `=destroy`(o: var Obj) = discard

proc main =
  var a = Obj(data: 42)
  var b = ensureMove(a)  # compiler-verified move
  doAssert b.data == 42

main()
echo "C30: PASS"
