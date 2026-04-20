import std/osproc, std/os, std/strutils

proc main() =
  let tmpdir = getTempDir()
  let childFile = tmpdir / "TestC01C02_child.nim"
  writeFile(childFile, "echo \"child ok\"")

  block C01:
    let (output, exitCode) = execCmdEx("nim c -r " & childFile & " 2>&1")
    if output.contains("DEBUG BUILD") and exitCode == 0:
      echo "C01: PASS"
    else:
      echo "C01: FAIL: expected DEBUG BUILD in default mode output"

  block C02:
    let (output, exitCode) = execCmdEx("nim c -r -d:debug " & childFile & " 2>&1")
    if output.contains("DEBUG BUILD") and exitCode == 0:
      echo "C02: PASS"
    else:
      echo "C02: FAIL: expected DEBUG BUILD in -d:debug output"

main()
