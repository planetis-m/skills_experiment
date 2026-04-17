## Reference tests: module_docs.md, proc_and_type_docs.md, runnable_examples.md
## All three references verified via nim doc + HTML output inspection.

import std/[os, osproc, strutils]

let workDir = "/tmp/nim_doc_comments_ref"
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

# --- module_docs.md: line-style module docs ---
block ref_module_line:
  let html = runDoc("ref_module_line", """
## Utilities for parsing and validating service configuration values.
##
## Exported helpers in this module raise `ValueError` for invalid user input.

import std/strutils
proc placeholder*() = discard
""")
  doAssert "Utilities for parsing and validating service configuration values." in html
  doAssert "Exported helpers in this module raise" in html

# --- module_docs.md: block-style module docs ---
block ref_module_block:
  let html = runDoc("ref_module_block", """
##[
Utilities for parsing and validating service configuration values.

Exported helpers in this module raise `ValueError` for invalid user input.
]##

import std/strutils
proc placeholder*() = discard
""")
  doAssert "Utilities for parsing and validating service configuration values." in html
  doAssert "Exported helpers in this module raise" in html

# --- module_docs.md: top-level runnableExamples ---
block ref_module_runnable:
  let html = runDoc("ref_module_runnable", """
## Module with example.

runnableExamples:
  doAssert 1 + 1 == 2

proc placeholder*() = discard
""")
  doAssert "Module with example." in html

# --- proc_and_type_docs.md: proc docs ---
block ref_proc_doc:
  let html = runDoc("ref_proc_doc", """
type Token* = object

proc encodeToken*(value: Token): string =
  ## Encodes `value` as a compact URL-safe token.
  ##
  ## Raises `ValueError` if `value` cannot be represented in the target format.
  result = ""
""")
  doAssert "Encodes" in html
  doAssert "compact URL-safe token" in html
  doAssert "Raises" in html

# --- proc_and_type_docs.md: inline trailing type doc ---
block ref_type_inline:
  let html = runDoc("ref_type_inline", """
type
  Hash* = int ## A hash value.
""")
  doAssert "A hash value." in html

# --- proc_and_type_docs.md: multi-line type doc ---
block ref_type_multiline:
  let html = runDoc("ref_type_multiline", """
type
  TreePayload = object
  Tree* = object ## Mutable builder used to assemble output.
                 ## Copying shares the payload until mutation detaches it.
    p: ptr TreePayload
""")
  doAssert "Mutable builder used to assemble output." in html
  doAssert "Copying shares the payload" in html

# --- proc_and_type_docs.md: enum docs ---
block ref_enum_doc:
  let html = runDoc("ref_enum_doc", """
type
  XmlNodeKind* = enum ## Different kinds of XML nodes.
    xnText,           ## A text element.
    xnElement,        ## An element with zero or more children.
    xnComment         ## An XML comment.
""")
  doAssert "Different kinds of XML nodes." in html
  doAssert "A text element." in html
  doAssert "An element with zero or more children." in html
  doAssert "An XML comment." in html

# --- proc_and_type_docs.md: object field docs ---
block ref_field_doc:
  let html = runDoc("ref_field_doc", """
import std/tables
type
  RequestContext* = object ## Parsed request with validated headers and route parameters.
    headers*: Table[string, string] ## Request headers.
    routeParams*: Table[string, string] ## Decoded route parameters.
""")
  doAssert "Parsed request with validated headers" in html
  doAssert "Request headers." in html
  doAssert "Decoded route parameters." in html

# --- proc_and_type_docs.md: const docs ---
block ref_const_doc:
  let html = runDoc("ref_const_doc", """
const
  HeaderLimit* = 10_000 ## Maximum accepted header bytes.
  DefaultPort* = 443    ## Default HTTPS port for outbound requests.
""")
  doAssert "Maximum accepted header bytes." in html
  doAssert "Default HTTPS port for outbound requests." in html

# --- runnable_examples.md: basic runnableExamples in proc ---
block ref_runnable_basic:
  let html = runDoc("ref_runnable_basic", """
type Token* = object
proc sampleToken*(): Token = Token()
proc encodeToken*(value: Token): string =
  ## Encodes `value` as a compact URL-safe token.
  runnableExamples:
    let token = encodeToken(sampleToken())
    doAssert token.len == 0
  result = ""
""")
  doAssert "Encodes" in html

# --- runnable_examples.md: parameterized compile flags ---
block ref_runnable_flags:
  let html = runDoc("ref_runnable_flags", """
proc flagged*(): string =
  ## Uses a compile-time define.
  runnableExamples("-d:myflag"):
    when defined(myflag):
      doAssert true
    else:
      doAssert false
  result = "ok"
""")
  doAssert "Uses a compile-time define." in html

echo "ref_doc_comments: PASS"
