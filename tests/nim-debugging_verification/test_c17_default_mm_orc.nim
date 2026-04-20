import std/osproc, std/os, std/strutils

proc main() =
  let tmpdir = getTempDir()
  let childFile = tmpdir / "TestC17_child.nim"
  writeFile(childFile, "echo \"ok\"")
  let (output, _) = execCmdEx("nim c -r " & childFile & " 2>&1")
  if output.contains("mm: orc"):
    echo "C17: PASS"
  else:
    echo "C17: FAIL: expected 'mm: orc' in default build output"

main()
