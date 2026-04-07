# test_expandArc_verification.nim
# This file exists to be compiled with --expandArc:main to show
# exactly which hooks the compiler inserts for each operation.
#
# Usage: nim r --mm:orc --expandArc:main test_expandArc_verification.nim
#
# Expected insertions:
#   var b = a           →  b = a; =wasMoved(a)             (move)
#   var c = dup(a)      →  (manual =dup call)
#   b = d               →  =sink(b, d); =wasMoved(d)       (synthesized sink)
#   x = x               →  (eliminated, no hooks called)   (self-sink removed)
#   finally block       →  =destroy on all locals           (RAII)

import std/assertions

var destroyCount = 0
var sinkCount = 0
var copyCount = 0

type
  Buf = object
    data: ptr int

proc `=destroy`*(x: var Buf) =
  if x.data != nil:
    destroyCount.inc()
    dealloc(x.data)
    x.data = nil

proc `=wasMoved`*(x: var Buf) =
  x.data = nil

proc `=copy`*(dest: var Buf; src: Buf) =
  copyCount.inc()
  if dest.data != src.data:
    `=destroy`(dest)
    `=wasMoved`(dest)
    if src.data != nil:
      dest.data = create(int)
      dest.data[] = src.data[]

proc `=dup`*(src: Buf): Buf {.nodestroy.} =
  result = Buf(data: nil)
  if src.data != nil:
    result.data = create(int)
    result.data[] = src.data[]

proc main() =
  var a: Buf
  a.data = create(int)
  a.data[] = 1

  # MOVE: var b = a → expandArc shows: b = a; =wasMoved(a)
  var b = a
  doAssert b.data[] == 1
  doAssert a.data == nil

  # DUP: explicit =dup call
  var c = `=dup`(b)
  doAssert c.data[] == 1
  doAssert c.data != b.data

  # SINK: b = d → expandArc shows: =sink(b, d); =wasMoved(d)
  var d: Buf
  d.data = create(int)
  d.data[] = 2
  b = d
  doAssert b.data[] == 2

  # SELF-SINK: c = c → expandArc shows: nothing (eliminated)
  c = c

  echo "destroyCount=", destroyCount, " copyCount=", copyCount
  echo "Run with --expandArc:main to see hook insertions"

main()
