import std/osproc, std/os, std/strutils

proc main() =
  let tmpdir = getTempDir()
  let childClean = tmpdir / "TestC22_clean.nim"
  writeFile(childClean, """
proc main() =
  var p = alloc(64)
  var arr = cast[ptr int](p)
  arr[] = 42
  echo arr[]
  dealloc(p)
main()
""")
  let outbin = tmpdir / "test_c22_valgrind_bin"
  let (compOut, compExit) = execCmdEx("nim c -o:" & outbin & " " & childClean & " 2>&1")
  if compExit != 0:
    echo "C22: FAIL: compile failed: ", compOut
  else:
    let (vgOut, vgExit) = execCmdEx("valgrind --leak-check=full --error-exitcode=1 " & outbin & " 2>&1")
    if vgExit == 0 and vgOut.contains("ERROR SUMMARY: 0 errors"):
      echo "C22: PASS"
    else:
      echo "C22: FAIL: valgrind exit=", vgExit

main()
