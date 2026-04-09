# Test C12, C13: dynlib imports with platform-conditional library names.
import std/os

const sourceDir = currentSourcePath.parentDir()

when defined(windows):
  const
    helperLib = sourceDir / "c12_dynlib_helper.dll"
    buildCmd = "cc -shared -o " & quoteShell(helperLib) & " " &
      quoteShell(sourceDir / "c12_dynlib_helper.c")
elif defined(macosx):
  const
    helperLib = sourceDir / "libc12_dynlib_helper.dylib"
    buildCmd = "cc -shared -fPIC -o " & quoteShell(helperLib) & " " &
      quoteShell(sourceDir / "c12_dynlib_helper.c")
else:
  const
    helperLib = sourceDir / "libc12_dynlib_helper.so"
    buildCmd = "cc -shared -fPIC -o " & quoteShell(helperLib) & " " &
      quoteShell(sourceDir / "c12_dynlib_helper.c")

static:
  let compileResult = gorgeEx(buildCmd)
  doAssert compileResult.exitCode == 0, compileResult.output

proc helperAdd(a, b: cint): cint {.cdecl, dynlib: helperLib, importc: "helper_add".}

doAssert helperAdd(20, 22) == 42

echo "C12_C13: PASS"
