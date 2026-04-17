# Test: representation_default.md reference compiles and works
type
  Rect = object
    x, y, w, h: int

  RectRef = ref object
    x, y, w, h: int

let a = Rect(x: 12, y: 22, w: 40, h: 80)
var copied = a
copied.x = 10
doAssert a.x == 12
doAssert copied.x == 10

var r = RectRef(x: 12, y: 22, w: 40, h: 80)
var alias = r
alias.x = 10
doAssert r.x == 10
doAssert alias.x == 10

echo "ref_representation_default: PASS"
