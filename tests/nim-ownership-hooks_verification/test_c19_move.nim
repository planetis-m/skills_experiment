# C19: move(x) forces move. Source is moved-from.
type Val = object
  data: ptr int

proc `=destroy`*(x: var Val) =
  if x.data != nil:
    dealloc(x.data)
    x.data = nil

proc `=wasMoved`*(x: var Val) = x.data = nil

proc `=copy`*(dest: var Val; src: Val) =
  `=destroy`(dest)
  `=wasMoved`(dest)
  if src.data != nil:
    dest.data = create(int)
    dest.data[] = src.data[]

proc main() =
  var a: Val
  a.data = create(int)
  a.data[] = 42
  var b = move(a)
  doAssert b.data[] == 42
  doAssert a.data == nil
  echo "C19: PASS"
main()
