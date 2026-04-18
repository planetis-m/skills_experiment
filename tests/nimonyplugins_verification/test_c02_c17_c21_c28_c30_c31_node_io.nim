# Test C02, C17, C21, C28, C30, C31:
# NifCursor copy semantics and lifetime, line-info helpers, raw tag inspection,
# NIF template parsing, and explicit load/save round-trip.
import nimony/lib/nimonyplugins
import std/[os, strutils]

proc makeNode(): NifCursor =
  var t = createTree()
  t.withTree(StmtsS, NoLineInfo):
    t.addIdent "kept"
    t.addIdent "alive"
  result = snapshot(t)

proc main() =
  # C02, C31: copied NifCursors are independent read handles and keep the snapshot alive.
  var n = makeNode()
  doAssert n.stmtKind == StmtsS
  var probe = n
  inc probe
  doAssert probe.identText == "kept"
  doAssert n.stmtKind == StmtsS
  doAssert renderNode(n).contains("kept")

  # C17: invalid line info reports no source location.
  doAssert not isValid(NoLineInfo)
  doAssert filePath(NoLineInfo) == ""
  let pos = lineCol(NoLineInfo)
  doAssert pos.line == 0
  doAssert pos.col == 0

  # C21: raw tag helpers inspect the current ParLe token.
  doAssert n.tagText == $n.tag
  doAssert n.tagText == $n.tagId

  # C28: %~ substitutes named NifBuilder fragments into a NIF template.
  let templ = `%~`(
    "(call $fn $arg)",
    [("fn", ~ident("echo")), ("arg", ~"hello")]
  )
  doAssert not templ.isEmpty
  let rendered = renderTree(templ)
  doAssert rendered.contains("echo")
  doAssert rendered.contains("hello")

  # C30: explicit save/load round-trip through a real .nif file.
  let tmpFile = getTempDir() / "nimonyplugins_roundtrip.nif"
  saveTree(templ, tmpFile)
  defer:
    if fileExists(tmpFile):
      removeFile(tmpFile)

  let loaded = loadPluginInput(tmpFile)
  doAssert loaded.exprKind == CallX
  doAssert renderNode(loaded).contains("echo")

  echo "C02_C17_C21_C28_C30_C31: PASS"

main()
