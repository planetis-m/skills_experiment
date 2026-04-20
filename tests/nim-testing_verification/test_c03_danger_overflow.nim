import testlib

proc overflow(a, b: int): int = a + b

when defined(danger):
  let result = overflow(high(int) - 1, 2)
  doAssert result < high(int) - 1, "C03: overflow must wrap in danger mode"
  echo "C03: PASS"
else:
  var raised = false
  try:
    discard overflow(high(int) - 1, 2)
  except OverflowDefect:
    raised = true
  doAssert raised, "C03 VERIFY: overflow should raise in non-danger mode"
  echo "C03: PASS (non-danger: OverflowDefect confirmed)"
