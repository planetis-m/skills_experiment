proc add(a, b: int): int {.noSideEffect.} =
  debugEcho "a=", a, " b=", b
  return a + b

proc main() =
  let r = add(3, 4)
  if r == 7:
    echo "C12: PASS"
  else:
    echo "C12: FAIL: expected 7 got ", r

main()
