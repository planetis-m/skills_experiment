## C20: "Use {.since: (version).} pragmas on procs added after initial release
## to document API evolution."
##
## NOTE: {.since.} is a stdlib-internal pragma defined in std/private/since.nim
## as a template. It is NOT available to user code. The claim is partially
## incorrect — user code cannot use {.since.} directly. The principle of
## documenting API additions with version info is sound, but the mechanism
## is stdlib-only.

import std/assertions

block version_guards_with_when:
  ## The correct user-level pattern is `when` guards with NimVersion constants,
  ## not {.since.} pragma.
  when (NimMajor, NimMinor) >= (2, 0):
    let isNim2Plus = true
  else:
    let isNim2Plus = false

  when (NimMajor, NimMinor, NimPatch) >= (2, 3, 1):
    let isAtLeast231 = true
  else:
    let isAtLeast231 = false

  doAssert isNim2Plus, "we're on Nim 2.x"
  doAssert isAtLeast231, "we're on Nim 2.3.1+"

block since_pragma_is_stdlib_internal:
  ## {.since.} pragma is defined in std/private/since as a template.
  ## It works in stdlib code because that code imports it.
  ## It does NOT work in user code (causes "invalid pragma" error).
  ## This confirms the pragma is stdlib-internal, not a language feature.
  doAssert not compiles(
    block:
      proc myApi(): int {.since: (1, 3).} = 42
  ), "{.since.} is not available in user code"

block api_evolution_with_since_template:
  ## The `since` template (from std/private/since) can be used to conditionally
  ## include code. But it requires importing std/private/since.
  ## For user APIs, use `when (NimMajor, NimMinor) >= (x, y)` instead.
  const myApiVersion = (2, 0)
  when (NimMajor, NimMinor) >= myApiVersion:
    proc newApi(): string = "available"
    doAssert newApi() == "available"
  else:
    doAssert false, "should not reach here on Nim 2.x"

echo "C20: PASS"
