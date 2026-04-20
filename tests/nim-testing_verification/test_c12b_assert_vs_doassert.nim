block assert_compiled_out_in_danger:
  when defined(danger):
    assert false, "assert should be compiled out in danger"
    echo "C12b: PASS (assert was compiled out in danger)"
  else:
    var raised = false
    try:
      assert false, "assert fires in non-danger"
    except AssertionDefect:
      raised = true
    doAssert raised, "C12b: assert must raise in non-danger"
    echo "C12b: PASS (assert raised in non-danger mode)"

block doassert_always_fires:
  var raised = false
  try:
    doAssert false, "doAssert always fires"
  except AssertionDefect:
    raised = true
  doAssert raised, "C12b: doAssert must always raise"
  echo "C12b: PASS (doAssert raised in all modes)"
