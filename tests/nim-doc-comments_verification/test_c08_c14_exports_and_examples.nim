## C08-C14: Exports, runnableExamples, and declaration-attached docs.

import std/[os, osproc, strutils]

let workDir = "/tmp/nim_doc_comments_c08_c14"
let nimcache = workDir / "nimcache"
removeDir(workDir)
createDir(workDir)
createDir(nimcache)

proc runDoc(name, source: string; extraArgs = ""): tuple[output: string, exitCode: int, html: string] =
  let src = workDir / (name & ".nim")
  writeFile(src, source)
  let cmd = "nim doc --nimcache:" & nimcache.quoteShell &
    " --outdir:" & workDir.quoteShell & " " & extraArgs & " " & src.quoteShell
  let (output, exitCode) = execCmdEx(cmd)
  var html = ""
  let htmlPath = workDir / (name & ".html")
  if fileExists(htmlPath):
    html = readFile(htmlPath)
  (output, exitCode, html)

block c08:
  let res = runDoc("c08", """
proc exported*(x: int): int =
  ## This is exported.
  x

proc hidden(x: int): int =
  ## This is not exported.
  x
""")
  doAssert res.exitCode == 0
  doAssert "This is exported." in res.html
  doAssert "This is not exported." notin res.html

block c09:
  let res = runDoc("c09", """
proc bad*(x: int): int =
  ## Bad proc.
  runnableExamples:
    doAssert false
  x
""")
  doAssert res.exitCode != 0

block c10:
  let res = runDoc("c10", """
proc flagged*(): string =
  ## Uses a define.
  runnableExamples("-d:myflag"):
    when defined(myflag):
      doAssert true
    else:
      doAssert false
  result = "ok"
""")
  doAssert res.exitCode == 0
  doAssert "Uses a define." in res.html

block c11:
  let res = runDoc("c11", """
type
  Color* = enum ## Colors.
    cRed,    ## The red color.
    cGreen,  ## The green color.
    cBlue    ## The blue color.
""")
  doAssert res.exitCode == 0
  doAssert "The red color." in res.html
  doAssert "The green color." in res.html

block c12:
  let res = runDoc("c12", """
type
  Request* = object ## Parsed request.
    headers*: string ## Request headers.
    port*: int       ## Port number.
""")
  doAssert res.exitCode == 0
  doAssert "Request headers." in res.html
  doAssert "Port number." in res.html

block c13:
  let res = runDoc("c13", """
const
  DefaultPort* = 443 ## Default HTTPS port.
""")
  doAssert res.exitCode == 0
  doAssert "Default HTTPS port." in res.html

block c14:
  let res = runDoc("c14", """
## Module with top-level example.

runnableExamples:
  doAssert 1 + 1 == 2

proc placeholder*() = discard
""")
  doAssert res.exitCode == 0
  doAssert "Module with top-level example." in res.html

echo "C08_C14: PASS"
