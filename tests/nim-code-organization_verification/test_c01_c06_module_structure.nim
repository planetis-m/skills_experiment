## C01-C06: Code organization claims.

import std/[os, osproc, strutils]

let workDir = "/tmp/nim_code_organization_c01_c06"
let nimcache = workDir / "nimcache"
removeDir(workDir)
createDir(workDir)
createDir(nimcache)

proc runNim(args: string): tuple[output: string, exitCode: int] =
  execCmdEx("nim " & args)

proc writeCase(name, source: string): string =
  let path = workDir / (name & ".nim")
  writeFile(path, source)
  path

block c01:
  let src = writeCase("c01", """
proc run() =
  var counter = 0
  proc incCounter() =
    inc counter
  for _ in 0..<100:
    incCounter()
  doAssert counter == 100

run()
echo "C01: PASS"
""")
  let res = runNim("c -r --mm:orc --nimcache:" & nimcache.quoteShell & " " & src.quoteShell)
  doAssert res.exitCode == 0, res.output

block c02:
  let src = writeCase("c02", """
type
  PipelineState = object
    step: int
    data: string

proc runStep(s: var PipelineState; payload: string) =
  inc s.step
  s.data = payload

var state = PipelineState(step: 0, data: "")
runStep(state, "hello")
runStep(state, "world")
doAssert state.step == 2
doAssert state.data == "world"
echo "C02: PASS"
""")
  let res = runNim("c -r --mm:orc --nimcache:" & nimcache.quoteShell & " " & src.quoteShell)
  doAssert res.exitCode == 0, res.output

block c03:
  let src = writeCase("c03", """
import std/strutils
proc foo*(): int = 42
""")
  let res = runNim("c --mm:orc --nimcache:" & nimcache.quoteShell & " " & src.quoteShell)
  doAssert res.exitCode == 0, res.output
  doAssert "UnusedImport" in res.output or "imported and not used" in res.output

block c04:
  let modDir = workDir / "mod"
  createDir(modDir)
  writeFile(modDir / "hidden.nim", """
proc internalProc(): int = 42
proc exportedProc*(): int = 99
""")

  let useExported = writeCase("c04a", """
import mod/hidden
echo exportedProc()
""")
  let resA = runNim("c -r --mm:orc --nimcache:" & nimcache.quoteShell &
    " --path:" & workDir.quoteShell & " " & useExported.quoteShell)
  doAssert resA.exitCode == 0, resA.output

  let useHidden = writeCase("c04b", """
import mod/hidden
echo internalProc()
""")
  let resB = runNim("c --mm:orc --nimcache:" & nimcache.quoteShell &
    " --path:" & workDir.quoteShell & " " & useHidden.quoteShell)
  doAssert resB.exitCode != 0

block c05:
  let src = writeCase("c05", """
proc run() =
  let total = 10
  var nextToWrite = 0
  proc flushReady() =
    if nextToWrite < total:
      inc nextToWrite
  flushReady()
  doAssert nextToWrite == 1

run()
echo "C05: PASS"
""")
  let res = runNim("c -r --mm:orc --nimcache:" & nimcache.quoteShell & " " & src.quoteShell)
  doAssert res.exitCode == 0, res.output

block c06:
  let src = writeCase("c06", """
type
  WriteState = object
    nextToWrite: int

proc flushReady(state: var WriteState; total: int) =
  if state.nextToWrite < total:
    inc state.nextToWrite

var s = WriteState(nextToWrite: 0)
flushReady(s, 10)
doAssert s.nextToWrite == 1
echo "C06: PASS"
""")
  let res = runNim("c -r --mm:orc --nimcache:" & nimcache.quoteShell & " " & src.quoteShell)
  doAssert res.exitCode == 0, res.output

echo "C01_C06: PASS"
