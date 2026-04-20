import std/osproc, std/os, std/strutils

proc main() =
  let here = getCurrentDir()
  let child = here / "test_c14_expandmacro_child.nim"
  let (output, exitCode) = execCmdEx("nim c --expandMacro:simpleLog " & child & " 2>&1")
  if output.contains("[ExpandMacro]") and output.contains("echo"):
    echo "C14: PASS"
  else:
    echo "C14: FAIL: expected [ExpandMacro] hint, got: ", output

main()
