# Test the three reference examples end-to-end: template, module, type plugins.
import std/[os, osproc, strutils]

let base = getTempDir() / "nimonyplugins_examples"
if dirExists(base):
  removeDir(base)
createDir(base)

let cache = getTempDir() / "nimonyplugins-examples-cache"
if dirExists(cache):
  removeDir(cache)
createDir(cache)

proc runNimony(appFile: string): (string, int) =
  result = execCmdEx("nimony c -r --path:/usr/lib64/nimony/src --nimcache:" & cache.quoteShell & " " & appFile.quoteShell)

# ── 1. Template plugin: popcount lookup table ───────────────────────

block:
  let d = base / "poplut"; createDir(d)

  writeFile(d / "poplut.nim", """
import nimonyplugins
proc popc8(i: int): int =
  var v = i; var c = 0
  while v != 0: v = v and (v - 1); inc c
  c
proc tr(n: Node): Tree =
  result = createTree()
  result.withTree BracketX, n.info:
    for i in 0..<256:
      result.addIntLit popc8(i)
var inp = loadPluginInput()
saveTree tr(inp)
""")

  writeFile(d / "app.nim", """
import std/syncio
import std/assertions
template buildPopcountLut(): untyped {.plugin: "poplut".}
let PopLut: array[256, int] = buildPopcountLut()
assert PopLut[0] == 0
assert PopLut[1] == 1
assert PopLut[13] == 3
assert PopLut[255] == 8
echo "TEMPLATE: PASS"
""")

  let (outp, code) = runNimony(d / "app.nim")
  doAssert code == 0, "Template plugin failed:\n" & outp
  doAssert "TEMPLATE: PASS" in outp, outp
  echo "TEMPLATE: PASS"

# ── 2. Module plugin: strip top-level blocks ────────────────────────

block:
  let d = base / "stripblocks"; createDir(d)

  writeFile(d / "stripblocks.nim", """
import nimonyplugins
proc transform(n: Node): Tree =
  result = createTree()
  var n = n
  if n.stmtKind == StmtsS: inc n
  result.withTree StmtsS, n.info:
    while n.kind != ParRi:
      if n.kind == ParLe and n.stmtKind == BlockS: skip n
      else: result.takeTree n
var inp = loadPluginInput()
saveTree transform(inp)
""")

  writeFile(d / "app.nim", """
import std/syncio
{.plugin: "stripblocks".}
echo "kept_a"
block:
  echo "removed_b"
echo "kept_c"
block:
  echo "removed_d"
  echo "also_removed"
echo "kept_e"
""")

  let (outp, code) = runNimony(d / "app.nim")
  doAssert code == 0, "Module plugin failed:\n" & outp
  for kept in ["kept_a", "kept_c", "kept_e"]:
    doAssert kept in outp, "Missing: " & kept & "\n" & outp
  for removed in ["removed_b", "removed_d", "also_removed"]:
    doAssert removed notin outp, "Should have been stripped: " & removed & "\n" & outp
  echo "MODULE: PASS"

# ── 3. Type plugin: identity passthrough with paramStr(3) ───────────

block:
  let d = base / "typeplugin"; createDir(d)

  writeFile(d / "traceable.nim", """
type
  Traceable* {.plugin: "traceplugin".} = object
    id*: int
    name*: string
""")

  writeFile(d / "traceplugin.nim", """
import nimonyplugins
import std/os
proc transform(n: Node): Tree =
  result = createTree()
  var n = n
  if n.stmtKind == StmtsS: inc n
  result.withTree StmtsS, n.info:
    while n.kind != ParRi:
      result.takeTree n
let moduleAst = loadPluginInput()
let typeAst = loadPluginInput(paramStr(3))
discard renderNode(typeAst)
saveTree transform(moduleAst)
""")

  writeFile(d / "app.nim", """
import std/syncio
import traceable
var item = Traceable(id: 1, name: "hello")
item.id = 42
item.name = "world"
echo item.id
echo item.name
""")

  let (outp, code) = runNimony(d / "app.nim")
  doAssert code == 0, "Type plugin failed:\n" & outp
  doAssert "42" in outp, outp
  doAssert "world" in outp, outp
  echo "TYPE: PASS"

echo "ALL_EXAMPLES: PASS"
