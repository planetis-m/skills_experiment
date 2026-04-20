import std/osproc, std/os, std/strutils

proc main() =
  let here = getCurrentDir()
  let child = here / "test_c19_c23_c28_asan_oom_child.nim"
  let tmpdir = getTempDir()
  let outbin = tmpdir / "test_c19_c23_c28_asan_oom_bin"

  block C19_C23_C28:
    let compileCmd = "nim c --passC:\"-fsanitize=address -fno-omit-frame-pointer\" --passL:\"-fsanitize=address -fno-omit-frame-pointer\" -g -d:noSignalHandler -d:useMalloc -o:" & outbin & " " & child
    let (compOut, compExit) = execCmdEx(compileCmd & " 2>&1")
    if compExit != 0:
      echo "C19: FAIL: compile failed: ", compOut
      echo "C23: SKIP"
      echo "C28: SKIP"
    else:
      let (runOut, _) = execCmdEx(outbin & " 2>&1")
      if runOut.contains("AddressSanitizer") and runOut.contains("heap-buffer-overflow"):
        echo "C19: PASS"
      else:
        echo "C19: FAIL: expected ASan heap-buffer-overflow"

      if not runOut.contains("noSignalHandler"):
        echo "C23: PASS"
      else:
        echo "C23: FAIL: signal handler appears active"

      if runOut.contains(".nim"):
        echo "C28: PASS"
      else:
        echo "C28: FAIL: expected .nim in ASan report"

main()
