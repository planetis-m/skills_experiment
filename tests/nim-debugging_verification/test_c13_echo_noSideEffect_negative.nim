proc add(a, b: int): int {.noSideEffect.} =
  echo "a=", a, " b=", b
  return a + b

echo add(3, 4)
