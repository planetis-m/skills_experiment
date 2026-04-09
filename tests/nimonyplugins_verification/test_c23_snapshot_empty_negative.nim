# Test C23: snapshot on an empty Tree asserts at runtime.
import std/[os, osproc, strutils]

proc main() =
  let base = getTempDir() / "nimonyplugins_snapshot_empty"
  createDir(base)
  let src = base / "snapshot_empty.nim"
  let nimcacheDir = base / "nimcache"
  createDir(nimcacheDir)

  writeFile(src, """
import nimony/lib/nimonyplugins
var t = createTree()
discard snapshot(t)
""")

  let cmd =
    "nim c -r --mm:orc --path:/usr/lib64/nimony/src --nimcache:" &
    quoteShell(nimcacheDir) & " " & quoteShell(src)
  let res = execCmdEx(cmd)
  doAssert res.exitCode != 0
  doAssert res.output.contains("cannot snapshot empty Tree")

  echo "C23: PASS"

main()
