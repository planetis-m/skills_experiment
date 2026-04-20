import std/osproc, std/os, std/strutils

const childSrc = staticRead("test_c03_c04_c05_c06_c07_c08_stack_trace_child.nim")

proc checkTrace(mode, expected: string): bool =
  let tmpdir = getTempDir()
  let childFile = tmpdir / "StackTraceTest_child.nim"
  writeFile(childFile, childSrc)
  let (output, exitCode) = execCmdEx("nim c -r " & mode & " " & childFile & " 2>&1")
  result = output.contains(expected)
  if not result:
    echo "  mode='", mode, "' expected='", expected, "'"
    echo "  output: ", output[0..min(output.len-1, 500)]

proc main() =
  block C03:
    if checkTrace("", "inner") and checkTrace("", "outer"):
      echo "C03: PASS"
    else:
      echo "C03: FAIL: default build should show full trace"

  block C04:
    let ok = checkTrace("-d:release", "inner")
    let (fullOut, _) = execCmdEx("nim c -r -d:release " & getTempDir() / "StackTraceTest_child.nim" & " 2>&1")
    let hasOuter = fullOut.contains("outer")
    if ok and not hasOuter:
      echo "C04: PASS"
    else:
      echo "C04: FAIL: release should show only raising frame"

  block C05:
    let (outDanger, _) = execCmdEx("nim c -r -d:danger " & getTempDir() / "StackTraceTest_child.nim" & " 2>&1")
    let hasInner = outDanger.contains("inner")
    let hasOuter = outDanger.contains("outer")
    if hasInner and not hasOuter:
      echo "C05: PASS"
    else:
      echo "C05: FAIL: danger should show only raising frame"

  block C06:
    let tmpdir = getTempDir()
    let childWst = tmpdir / "StackTraceTest_wst_child.nim"
    writeFile(childWst, "proc inner() = writeStackTrace()\nproc main() = inner()\nmain()")
    let (output6, _) = execCmdEx("nim c -r -d:release " & childWst & " 2>&1")
    if output6.contains("No stack traceback available"):
      echo "C06: PASS"
    else:
      echo "C06: FAIL: writeStackTrace in release should say 'No stack traceback available'"

  block C07:
    let tmpdir = getTempDir()
    let childWst = tmpdir / "StackTraceTest_wst_danger_child.nim"
    writeFile(childWst, "proc inner() = writeStackTrace()\nproc main() = inner()\nmain()")
    let (output7, _) = execCmdEx("nim c -r -d:danger " & childWst & " 2>&1")
    if output7.contains("No stack traceback available"):
      echo "C07: PASS"
    else:
      echo "C07: FAIL: writeStackTrace in danger should say 'No stack traceback available'"

  block C08:
    let tmpdir = getTempDir()
    let childE = tmpdir / "StackTraceTest_restore_child.nim"
    writeFile(childE, childSrc)
    let (output8, _) = execCmdEx("nim c -r -d:release --stackTrace:on --lineTrace:on " & childE & " 2>&1")
    if output8.contains("inner") and output8.contains("outer"):
      echo "C08: PASS"
    else:
      echo "C08: FAIL: --stackTrace:on --lineTrace:on should restore full trace"

main()
