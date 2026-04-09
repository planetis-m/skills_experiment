## C01-C07: Core module and declaration doc layouts.

import std/[os, osproc, strutils]

let workDir = "/tmp/nim_doc_comments_c01_c07"
let nimcache = workDir / "nimcache"
removeDir(workDir)
createDir(workDir)
createDir(nimcache)

proc runDoc(name, source: string): string =
  let src = workDir / (name & ".nim")
  writeFile(src, source)
  let cmd = "nim doc --nimcache:" & nimcache.quoteShell &
    " --outdir:" & workDir.quoteShell & " " & src.quoteShell
  let (output, exitCode) = execCmdEx(cmd)
  doAssert exitCode == 0, "nim doc failed for " & name & ":\n" & output
  let html = workDir / (name & ".html")
  doAssert fileExists(html), "expected HTML output for " & name
  result = readFile(html)

block c01:
  let html = runDoc("c01", """
## Module doc for C01.

import std/strutils
proc foo*(): string = "bar"
""")
  doAssert """<p class="module-desc">""" in html
  doAssert "Module doc for C01." in html

block c02:
  let html = runDoc("c02", """
##[
Block module doc for C02.
]##

proc bar*(): int = 1
""")
  doAssert """<p class="module-desc">""" in html
  doAssert "Block module doc for C02." in html

block c03:
  let html = runDoc("c03", """
proc greet*(name: string): string =
  ## Greets the person by name.
  result = "hello " & name
""")
  doAssert "Greets the person by name." in html

block c04:
  let html = runDoc("c04", """
proc double*(x: int): int =
  ## Doubles the value.
  runnableExamples:
    doAssert double(3) == 6
  result = x * 2
""")
  doAssert "Doubles the value." in html

block c05:
  let html = runDoc("c05", """
type
  Hash* = int ## A hash value.
""")
  doAssert "A hash value." in html

block c06:
  let html = runDoc("c06", """
type
  Tree* = object ## Mutable builder.
                ## Copying shares the payload.
    p: pointer
""")
  doAssert "Mutable builder." in html
  doAssert "Copying shares the payload." in html

block c07:
  let html = runDoc("c07", """
## Module docs for generated HTML.

proc marker*(): int = 7
""")
  doAssert "Module docs for generated HTML." in html

echo "C01_C07: PASS"
