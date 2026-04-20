import std/osproc, std/os, std/strutils

proc main() =
  let tmpdir = getTempDir()

  block C09:
    let childFile = tmpdir / "TestC09_child.nim"
    writeFile(childFile, "proc inner() = raise newException(ValueError, \"err\")\nproc main() = inner()\nmain()")
    let (output, _) = execCmdEx("nim c -r -d:release --lineTrace:on " & childFile & " 2>&1")
    if output.contains("inner"):
      echo "C09: PASS"
    else:
      echo "C09: FAIL: --lineTrace:on should imply --stackTrace:on"

  block C10:
    let src = "proc inner() = raise newException(ValueError, \"err\")\nproc outer() = inner()\nproc main() = outer()\nmain()"

    let childOn = tmpdir / "TestC10_on_child.nim"
    writeFile(childOn, src)
    let (outputOn, _) = execCmdEx("nim c -r -f --excessiveStackTrace:on -d:release --stackTrace:on --lineTrace:on " & childOn & " 2>&1")
    let onHasFullPath = outputOn.contains("/TestC10_on_child.nim(")

    let childOff = tmpdir / "TestC10_off_child.nim"
    writeFile(childOff, src)
    let (outputOff, _) = execCmdEx("nim c -r -f --excessiveStackTrace:off -d:release --stackTrace:on --lineTrace:on " & childOff & " 2>&1")
    let offHasFullPath = outputOff.contains("/TestC10_off_child.nim(")

    if onHasFullPath and not offHasFullPath:
      echo "C10: PASS"
    else:
      echo "C10: FAIL: on_full_path=", onHasFullPath, " off_full_path=", offHasFullPath

main()
