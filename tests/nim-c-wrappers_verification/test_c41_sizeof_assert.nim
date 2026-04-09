# Test C41: static doAssert sizeof for struct layout verification
type
  # Simulate a C struct: struct Point { int x; int y; };
  Point = object
    x: cint
    y: cint

static:
  doAssert sizeof(Point) == 8
  doAssert offsetOf(Point, x) == 0
  doAssert offsetOf(Point, y) == 4

echo "C41: PASS"
