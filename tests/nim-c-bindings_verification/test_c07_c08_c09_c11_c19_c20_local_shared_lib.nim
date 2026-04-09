# Test C07, C08, C09, C11, C19, C20:
# - local shared libs use repo-relative `-L` + `-l`
# - the shared lib is colocated next to the executable
# - Linux runtime resolution uses `$ORIGIN` without extra env mutation
import std/os

const
  sourceDir = currentSourcePath.parentDir()
  repoRelLibDir = "tests/nim-c-bindings_verification/third_party/c07_local_helper"
  helperHeader = "third_party/c07_local_helper/c07_local_helper.h"
  absLibDir = sourceDir / "third_party" / "c07_local_helper"

when defined(linux):
  const
    helperLibName = "libc07_local_helper.so"
    helperBuildPath = absLibDir / helperLibName

  static:
    let build = gorgeEx(
      "cc -shared -fPIC -o " & quoteShell(helperBuildPath) & " " &
      quoteShell(absLibDir / "c07_local_helper.c")
    )
    doAssert build.exitCode == 0, build.output

    let colocate = gorgeEx(
      "cp " & quoteShell(helperBuildPath) & " " &
      quoteShell(sourceDir / helperLibName)
    )
    doAssert colocate.exitCode == 0, colocate.output

  {.passL: "-L" & repoRelLibDir & " -lc07_local_helper".}
  {.passL: "-Wl,-rpath,\\$ORIGIN".}

  proc c07HelperAdd(a, b: cint): cint
    {.importc: "c07_helper_add", cdecl, header: helperHeader.}

  doAssert c07HelperAdd(20, 22) == 42
  doAssert fileExists(getAppDir() / helperLibName)

echo "C07_C08_C09_C11_C19_C20: PASS"
