# Verify: catching bare Exception also catches Defect (which signals a bug)

proc test() =
  # Defect IS caught by bare Exception
  var defectCaughtByException = false
  try:
    raise newException(AccessViolationDefect, "bug")
  except Exception:
    defectCaughtByException = true
  doAssert defectCaughtByException,
    "bare Exception catches Defect — this is why you should not catch bare Exception"

  # Defect is NOT caught by CatchableError — it propagates out
  var defectEscaped = false
  try:
    try:
      raise newException(AccessViolationDefect, "bug")
    except CatchableError:
      defectEscaped = false
    # If we get here, CatchableError caught the Defect — that would be wrong
    defectEscaped = false
    doAssert false, "CatchableError should NOT catch Defect but it did"
  except Exception:
    # The Defect escaped the inner CatchableError and landed here
    defectEscaped = true
  doAssert defectEscaped,
    "Defect must escape CatchableError and only be caught by bare Exception"

test()
echo "EXCEPTION_VS_DEFECT: PASS"
