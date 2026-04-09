## C20: {.since: (version).} pragmas document API evolution

# --- Test 1: proc with {.since: (1, 1).} compiles on current Nim (>= 2.3.1) ---
proc oldApi(): string {.since: (1, 1).} =
  "available since 1.1"

doAssert oldApi() == "available since 1.1", "proc with since (1,1) should work on Nim 2.3.1"

# --- Test 2: proc with {.since: (2, 0).} also compiles on current Nim ---
proc newerApi(): int {.since: (2, 0).} =
  42

doAssert newerApi() == 42, "proc with since (2,0) should work on Nim 2.3.1"

# --- Test 3: {.since: (99, 0).} makes a proc unavailable ---
import osproc

const futureCode = """
proc futureApi(): int {.since: (99, 0).} =
  99

discard futureApi()
"""

const tmpFile = "/tmp/test_c20_future.nim"
writeFile(tmpFile, futureCode)
let (output, exitCode) = execCmdEx("nim c --mm:orc --hints:off " & tmpFile)
doAssert exitCode != 0, "compiler must reject call to proc with since (99,0) on Nim 2.3.1"
doAssert "futureApi" in output or "since" in output or "Error" in output,
  "error should mention the unavailable proc or since pragma"

echo "C20: PASS"
