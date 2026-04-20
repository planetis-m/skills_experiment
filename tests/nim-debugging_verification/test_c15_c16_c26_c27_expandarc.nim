import std/osproc, std/os, std/strutils

proc main() =
  let here = getCurrentDir()
  let child = here / "test_c15_c16_c26_c27_expandarc_child.nim"

  block C15:
    let (output, _) = execCmdEx("nim c --expandArc:extractCopy " & child & " 2>&1")
    if output.contains("=copy") and output.contains("end of expandArc"):
      echo "C15: PASS"
    else:
      echo "C15: FAIL: expected =copy in expandArc output"

  block C16:
    let (outputOrc, _) = execCmdEx("nim c --expandArc:extractCopy --mm:orc " & child & " 2>&1")
    let (outputArc, _) = execCmdEx("nim c --expandArc:extractCopy --mm:arc " & child & " 2>&1")
    let (outputAtomic, _) = execCmdEx("nim c --expandArc:extractCopy --mm:atomicArc " & child & " 2>&1")
    let allSame = outputOrc.contains("=copy") and outputArc.contains("=copy") and outputAtomic.contains("=copy")
    if allSame:
      echo "C16: PASS"
    else:
      echo "C16: FAIL: expandArc output differs across mm modes"

  block C26:
    let (output, _) = execCmdEx("nim c --expandArc:extractMove " & child & " 2>&1")
    if output.contains("move") and not output.contains("=copy"):
      echo "C26: PASS"
    else:
      echo "C26: FAIL: expected move without =copy"

  block C27:
    let (output, _) = execCmdEx("nim c --expandArc:main " & child & " 2>&1")
    if output.contains("=destroy") and output.contains("finally"):
      echo "C27: PASS"
    else:
      echo "C27: FAIL: expected =destroy in finally block"

main()
