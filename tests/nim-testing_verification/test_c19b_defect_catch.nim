block except_assertiondefect_works:
  var caught = false
  try:
    doAssert false, "boom"
  except AssertionDefect:
    caught = true
  doAssert caught, "C19b: except AssertionDefect must catch"

block except_defect_works:
  var caught = false
  try:
    doAssert false, "boom"
  except Defect:
    caught = true
  doAssert caught, "C19b: except Defect must catch"

block except_exception_works:
  var caught = false
  try:
    doAssert false, "boom"
  except Exception:
    caught = true
  doAssert caught, "C19b: except Exception must catch"

echo "C19b: PASS"
