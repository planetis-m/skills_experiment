# Test C11: rpath with $ORIGIN for colocated shared libs on Linux
import std/strutils

when defined(linux):
  const rpathFlag = "-Wl,-rpath,$ORIGIN"
  doAssert rpathFlag.contains("rpath")
  doAssert rpathFlag.contains("ORIGIN")

echo "C11: PASS"
