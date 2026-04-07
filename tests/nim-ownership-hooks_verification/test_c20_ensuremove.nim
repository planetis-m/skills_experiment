# C20: ensureMove works for provable cases (rvalues, sink params).
type Val = object
  data: ptr int

proc `=destroy`*(x: var Val) =
  if x.data != nil:
    dealloc(x.data)
    x.data = nil

proc `=wasMoved`*(x: var Val) = x.data = nil

proc take(v: sink Val) =
  doAssert v.data != nil

proc main() =
  block:
    proc makeVal(): Val =
      result.data = create(int)
      result.data[] = 42
    take(ensureMove(makeVal()))
  echo "C20: PASS"
main()
