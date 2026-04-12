## C28-C30: explicit raises contracts and custom exception base choice

block c28:
  static:
    doAssert not compiles(block:
      proc mayRaise(): int =
        raise newException(ValueError, "boom")

      proc main() {.raises: [].} =
        discard mayRaise()
    ), "raises:[] should reject calling a proc that raises ValueError"

    doAssert compiles(block:
      proc mayRaise(): int =
        raise newException(ValueError, "boom")

      proc main() {.raises: [ValueError].} =
        discard mayRaise()
    ), "matching raises annotations should compile"

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
