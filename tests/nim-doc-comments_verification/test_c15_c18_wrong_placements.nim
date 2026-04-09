## C15-C18: Wrong placement cases for Nim doc comments.

import std/[os, osproc, strutils]

let workDir = "/tmp/nim_doc_comments_wrong_placements"
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
  result = readFile(workDir / (name & ".html"))

block c15:
  let html = runDoc("c15", """
## Proc doc before signature.
proc foo*(): int = 1
""")
  doAssert """<p class="module-desc">Proc doc before signature.</p>""" in html

block c16:
  let html = runDoc("c16", """
type
  ## Type doc above declaration.
  Thing* = object
    field*: int ## Field doc.
""")
  doAssert "Thing" in html
  doAssert "Type doc above declaration." notin html

block c17:
  let html = runDoc("c17", """
const
  ## Const doc above declaration.
  Answer* = 42
""")
  doAssert "Answer" in html
  doAssert "Const doc above declaration." notin html

block c18:
  let html = runDoc("c18", """
import std/strutils
## Module doc after import.
proc foo*(): int = 1
""")
  doAssert """<p class="module-desc">Module doc after import.</p>""" in html

echo "C15_C18: PASS"
