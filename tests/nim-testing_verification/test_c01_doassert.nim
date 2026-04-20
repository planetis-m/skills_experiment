import testlib

block:
  var raised = false
  try:
    doAssert false, "intentional failure"
  except AssertionDefect:
    raised = true
  doAssert raised, "C01: doAssert must raise AssertionDefect"

echo "C01: PASS"
