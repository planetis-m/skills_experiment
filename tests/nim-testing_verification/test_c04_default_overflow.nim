import testlib

proc overflow(a, b: int): int = a + b

when not defined(danger):
  var raised = false
  try:
    discard overflow(high(int) - 1, 2)
  except OverflowDefect:
    raised = true
  doAssert raised, "C04: OverflowDefect must be raised in default/release mode"
  echo "C04: PASS"
else:
  echo "C04: SKIP (danger mode)"
