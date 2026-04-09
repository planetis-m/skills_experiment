# Test C14: field order must match C exactly
# Demonstrating that reordering changes the struct layout
type
  Correct = object
    a: cint
    b: cint
  Wrong = object
    b: cint
    a: cint

static:
  doAssert offsetOf(Correct, a) == 0
  doAssert offsetOf(Correct, b) == 4
  doAssert offsetOf(Wrong, b) == 0  # swapped
  doAssert offsetOf(Wrong, a) == 4  # swapped

echo "C14: PASS"
