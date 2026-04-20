import std/osproc, std/os

proc main() =
  let tmpdir = getTempDir()
  let childFile = tmpdir / "TestC18_child.nim"
  writeFile(childFile, "echo \"ok\"")

  let (outA, exitA) = execCmdEx("nim c --debugger:native -o:" & tmpdir / "test_c18_a" & " " & childFile & " 2>&1")
  let (outB, exitB) = execCmdEx("nim c --debuginfo --linedir:on -o:" & tmpdir / "test_c18_b" & " " & childFile & " 2>&1")

  if exitA == 0 and exitB == 0:
    echo "C18: PASS"
  else:
    echo "C18: FAIL: --debugger:native or --debuginfo --linedir:on failed"
    echo "  native: ", outA
    echo "  explicit: ", outB

main()
