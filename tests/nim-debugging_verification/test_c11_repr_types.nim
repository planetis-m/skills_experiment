import std/strutils

type
  MyRef = ref object
    x: int
    s: string

proc main() =
  var r = MyRef(x: 42, s: "hello")
  var seq1 = @[1, 2, 3]
  var str1 = "world"
  var p = alloc(16)

  let reprR = repr(r)
  let reprSeq = repr(seq1)
  let reprStr = repr(str1)
  let reprP = repr(p)
  dealloc(p)

  var ok = true
  if not reprR.contains("x: 42") or not reprR.contains("s: \"hello\""):
    echo "C11: FAIL: ref repr unexpected: ", reprR
    ok = false
  if not reprSeq.contains("@[1, 2, 3]"):
    echo "C11: FAIL: seq repr unexpected: ", reprSeq
    ok = false
  if reprStr != "\"world\"":
    echo "C11: FAIL: string repr unexpected: ", reprStr
    ok = false
  if reprP.len < 4:
    echo "C11: FAIL: pointer repr too short: ", reprP
    ok = false

  if ok:
    echo "C11: PASS"

main()
