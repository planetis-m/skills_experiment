import std/osproc, std/os, std/strutils

proc main() =
  let here = getCurrentDir()
  let tmpdir = getTempDir()
  let childFile = tmpdir / "TestC21_child.nim"
  writeFile(childFile, """
proc main() =
  var p = alloc(16)
  var arr = cast[ptr UncheckedArray[int]](p)
  arr[0] = 42
  discard arr[5]
  dealloc(p)
main()
""")

  block C21_passC_only:
    let outbin = here / "test_c21_passC_only"
    let (compOut, compExit) = execCmdEx("nim c --passC:\"-fsanitize=address -fno-omit-frame-pointer\" -d:noSignalHandler -d:useMalloc -o:" & outbin & " " & childFile & " 2>&1")
    if compExit != 0:
      echo "C21: PASS (compile fails without --passL)"
    else:
      let (runOut, _) = execCmdEx(outbin & " 2>&1")
      if runOut.contains("AddressSanitizer"):
        echo "C21: NUANCED: ASan works with only --passC (linker auto-links on this system)"
      else:
        echo "C21: PASS (compiled but ASan not active without --passL)"

main()
