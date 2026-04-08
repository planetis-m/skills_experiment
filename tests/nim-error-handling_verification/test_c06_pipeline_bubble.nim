# C06: Pipeline errors bubble until caught at a boundary.

proc step1(): int =
  raise newException(ValueError, "step1 failed")

proc step2(): int =
  result = step1() + 1  # should not reach here

proc step3(): int =
  result = step2() + 1  # should not reach here

proc test() =
  var caught = false
  var msg = ""
  try:
    discard step3()
  except ValueError:
    caught = true
    msg = getCurrentExceptionMsg()
  doAssert caught, "Exception should propagate from step1 through step2 and step3"
  doAssert msg == "step1 failed", "Message should be preserved: " & msg

test()
echo "C06: PASS"
