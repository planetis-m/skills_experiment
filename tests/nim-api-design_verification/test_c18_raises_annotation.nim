## C18: {.raises: [].} makes exception surface explicit and is enforced at compile time

import std/[strutils]

# --- Test 1: proc marked {.raises: [].} that genuinely cannot raise compiles fine ---
proc addNoRaise(a, b: int): int {.raises: [].} =
  result = a + b

doAssert addNoRaise(3, 4) == 7, "raises:[] proc should compute correctly"

# --- Test 2: proc marked {.raises: [].} can call other {.raises: [].} procs ---
proc doubleNoRaise(x: int): int {.raises: [].} =
  addNoRaise(x, x)

doAssert doubleNoRaise(5) == 10, "raises:[] proc can call other raises:[] procs"

# --- Test 3: compiler enforces {.raises: [].} at compile time ---
# We verify this by writing a separate file that VIOLATES the pragma and confirming
# it fails to compile. This is done via staticExec / compile-time check.

import osproc

const failCode = """
proc mayRaise(): int =
  if true: raise newException(ValueError, "boom")
  result = 42

proc safeCall(): int {.raises: [].} =
  result = mayRaise()
"""

# Write the bad code to a temp file and try to compile it
const tmpFile = "/tmp/test_c18_bad_raises.nim"
writeFile(tmpFile, failCode)
let (output, exitCode) = execCmdEx("nim c --mm:orc --hints:off " & tmpFile)
doAssert exitCode != 0, "compiler must reject raises:[] proc that calls a raising proc"
doAssert "raises" in output or "can raise" in output or "Error" in output,
  "error message should mention raises constraint violation"

echo "C18: PASS"
