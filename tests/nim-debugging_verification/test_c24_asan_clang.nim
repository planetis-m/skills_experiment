import std/osproc, std/os, std/strutils

proc main() =
  let here = getCurrentDir()
  let child = here / "test_c19_c23_c28_asan_oom_child.nim"
  let tmpdir = getTempDir()
  let outbin = tmpdir / "test_c24_asan_clang_bin"

  let compileCmd = "nim c --cc:clang --passC:\"-fsanitize=address -fno-omit-frame-pointer\" --passL:\"-fsanitize=address -fno-omit-frame-pointer\" -g -d:noSignalHandler -d:useMalloc -o:" & outbin & " " & child
  let (compOut, compExit) = execCmdEx(compileCmd & " 2>&1")
  if compExit != 0:
    echo "C24: FAIL: compile with --cc:clang failed: ", compOut
  else:
    let (runOut, _) = execCmdEx(outbin & " 2>&1")
    if runOut.contains("AddressSanitizer") and runOut.contains("heap-buffer-overflow"):
      echo "C24: PASS"
    else:
      echo "C24: FAIL: expected ASan report with clang"

main()
