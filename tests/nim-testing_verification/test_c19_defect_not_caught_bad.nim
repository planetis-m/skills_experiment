block bare_except_fails:
  var caught = false
  try:
    doAssert false, "boom"
  except:
    caught = true
  doAssert caught, "C19: bare except should NOT catch AssertionDefect"

echo "C19: PASS"
