## C08-C09: nested procs may capture outer state by default; nimcall forbids capture

import std/[osproc, pathnorm, strutils]

proc makeCounter(start: int): proc(): int =
  var current = start

  proc nextValue(): int =
    inc current
    current

  result = nextValue

block c08:
  let counter = makeCounter(10)
  doAssert counter() == 11
  doAssert counter() == 12

block c09:
  let src = "/tmp/nim_code_organization_c09_negative.nim"
  writeFile(src, """
proc outer() =
  var nextToWrite = 0

  proc flushReady() {.nimcall.} =
    inc nextToWrite

  flushReady()

outer()
""")
  var normalizedSrc = src
  normalizedSrc = normalizePath(normalizedSrc)
  let (output, exitCode) = execCmdEx("nim c --nimcache:/tmp/nim-code-org-c09 " & normalizedSrc)
  doAssert exitCode != 0
  doAssert output.contains("illegal capture") or output.contains("nimcall") or output.contains("Error")

echo "C08_C09: PASS"
