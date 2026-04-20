import std/strutils

block stack_trace_default:
  var output = ""
  try:
    raise newException(ValueError, "test trace")
  except ValueError as e:
    output = e.getStackTrace()
  let hasFile = "test_c08" in output or "test_c08" in output.replace("\\", "/")
  when not defined(danger) and not defined(release):
    doAssert hasFile or output.len > 0, "C08: default mode should produce a stack trace, got: '" & output & "'"
  echo "C08: PASS"

echo "C08: PASS"
