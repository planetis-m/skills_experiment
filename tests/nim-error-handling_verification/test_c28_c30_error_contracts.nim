## C28-C30: explicit raises contracts and custom exception base choice

import std/[osproc, strutils]

block c28:
  let badSrc = "/tmp/nim_error_handling_c28_bad.nim"
  writeFile(badSrc, """
proc mayRaise(): int =
  raise newException(ValueError, "boom")

proc main() {.raises: [].} =
  discard mayRaise()
""")
  let (badOutput, badExitCode) = execCmdEx("nim c --hints:off --nimcache:/tmp/nim-error-handling-c28-bad " & badSrc)
  doAssert badExitCode != 0
  doAssert badOutput.contains("raises") or badOutput.contains("unlisted exception") or badOutput.contains("Error")

  let goodSrc = "/tmp/nim_error_handling_c28_good.nim"
  writeFile(goodSrc, """
proc mayRaise(): int =
  raise newException(ValueError, "boom")

proc main() {.raises: [ValueError].} =
  discard mayRaise()
""")
  let (goodOutput, goodExitCode) = execCmdEx("nim c --hints:off --nimcache:/tmp/nim-error-handling-c28-good " & goodSrc)
  doAssert goodExitCode == 0, goodOutput

block c30:
  type
    ConfigParseError = object of ValueError

  proc failParse() =
    raise newException(ConfigParseError, "bad config")

  var caughtSpecific = false
  try:
    failParse()
  except ConfigParseError:
    caughtSpecific = true
  doAssert caughtSpecific

  var caughtBase = false
  try:
    failParse()
  except ValueError:
    caughtBase = true
  doAssert caughtBase

echo "C28_C30: PASS"
