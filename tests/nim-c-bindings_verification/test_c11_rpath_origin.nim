## C11: rpath with $ORIGIN for colocated shared libs on Linux

{.passL: "-Wl,-rpath,\\$ORIGIN".}

import std/[os, osproc, strutils]

when defined(linux):
  let (output, exitCode) = execCmdEx("readelf -d " & quoteShell(getAppFilename()))
  doAssert exitCode == 0, "readelf should inspect the current test binary"
  doAssert output.contains("RUNPATH") or output.contains("RPATH"),
    "binary should contain a runtime search path entry"
  doAssert output.contains("[$ORIGIN]"),
    "binary runpath should preserve literal $ORIGIN"

echo "C11: PASS"
