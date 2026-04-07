# C13: lent T provides immutable borrow, no destructor injected.
type Container = object
  data: seq[int]

proc `[]`(x: Container; i: int): lent int = x.data[i]

proc main() =
  var c = Container(data: @[10, 20, 30])
  let val = c[1]
  doAssert val == 20
  echo "C13: PASS"
main()
