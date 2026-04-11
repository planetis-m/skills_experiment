## C20: user code should use when-guards; {.since.} is stdlib-internal

import osproc
import std/strutils

when (NimMajor, NimMinor) >= (2, 0):
  proc currentApi(): string =
    "available"
else:
  proc currentApi(): string =
    "fallback"

doAssert currentApi() == "available"

const invalidSinceCode = """
proc userApi(): int {.since: (1, 1).} =
  99

discard userApi()
"""

const tmpFile = "/tmp/test_c20_invalid_since.nim"
writeFile(tmpFile, invalidSinceCode)
let (output, exitCode) = execCmdEx("nim c --hints:off " & tmpFile)
doAssert exitCode != 0, "compiler must reject {.since.} in user code"
doAssert "invalid pragma" in output or "since" in output or "Error" in output

echo "C20: PASS"
