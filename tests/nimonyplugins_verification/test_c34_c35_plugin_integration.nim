# Test C34, C35: end-to-end plugin entrypoint via template {.plugin.}
# and default loadPluginInput()/saveTree() overloads.
import std/[os, osproc, strutils]

let base = getTempDir() / "nimonyplugins_e2e_plugin"
if dirExists(base):
  removeDir(base)
createDir(base)

let runtimeFile = base / "shoutdsl.nim"
let pluginFile = base / "shoutplugin.nim"
let appFile = base / "app.nim"

writeFile(runtimeFile, """
template shout*(spec: string): untyped {.plugin: "shoutplugin".}
""")

writeFile(pluginFile, """
import std/strutils
import nimonyplugins

proc extractArg(n: Node): Node =
  result = n
  if result.stmtKind == StmtsS:
    inc result
  if result.kind == ParLe and result.exprKind == SufX:
    inc result

let root = loadPluginInput()
let arg = extractArg(root)

if arg.kind == StringLit:
  var resultTree = createTree()
  resultTree.addStrLit(arg.stringValue.toUpperAscii)
  saveTree(resultTree)
else:
  saveTree errorTree("shout expects a string literal", arg)
""")

writeFile(appFile, """
import std / assertions
import std / syncio
import shoutdsl

assert shout"hello" == "HELLO"
echo "C34_C35: PASS"
""")

let cmd = "nimony c -r --path:/usr/lib64/nimony/src --nimcache:/tmp/nimonyplugins-e2e-cache " & appFile.quoteShell
let res = execCmdEx(cmd)
doAssert res.exitCode == 0, res.output
doAssert res.output.contains("C34_C35: PASS"), res.output

echo "C34_C35: PASS"
