## C23: plain object assignment copies; ref object assignment aliases

type
  Rect = object
    x, y, w, h: int

  RectRef = ref object
    x, y, w, h: int

block value_type_copy:
  let original = Rect(x: 12, y: 22, w: 40, h: 80)
  var copied = original
  copied.x = 10
  doAssert original.x == 12
  doAssert copied.x == 10

block ref_type_alias:
  var original = RectRef(x: 12, y: 22, w: 40, h: 80)
  var alias = original
  alias.x = 10
  doAssert original.x == 10
  doAssert alias.x == 10

echo "C23: PASS"
