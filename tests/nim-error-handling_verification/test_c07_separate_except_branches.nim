# C07: Separate except branches for different error types.

proc step1() =
  raise newException(IOError, "io failure")

proc step2() =
  raise newException(ValueError, "value failure")

proc test() =
  # IOError branch
  var ioHandled = false
  try:
    step1()
  except IOError:
    ioHandled = true
  except ValueError:
    doAssert false, "IOError should not reach ValueError handler"
  doAssert ioHandled

  # ValueError branch
  var valHandled = false
  try:
    step2()
  except IOError:
    doAssert false, "ValueError should not reach IOError handler"
  except ValueError:
    valHandled = true
  doAssert valHandled

  # Both branches in same try
  var which = ""
  try:
    step1()
  except IOError:
    which = "io"
  except ValueError:
    which = "val"
  doAssert which == "io"

  try:
    step2()
  except IOError:
    which = "io"
  except ValueError:
    which = "val"
  doAssert which == "val"

test()
echo "C07: PASS"
