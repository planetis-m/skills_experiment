## C02: Redundant runtime checks that restate existing type or proc contracts
##      should not be added unless required by a boundary.

proc sumNatural(a, b: Natural): int {.inline.} =
  result = a + b

proc sumWithRedundantCheck(a, b: Natural): int =
  if a < 0:    # dead code — Natural already guarantees a >= 0
    raise newException(ValueError, "a is negative")
  if b < 0:    # dead code — Natural already guarantees b >= 0
    raise newException(ValueError, "b is negative")
  result = a + b

proc callSumNatural(n: int): int {.inline.} =
  sumNatural(n, n)

proc callSumRedundant(n: int): int {.inline.} =
  sumWithRedundantCheck(n, n)

block valid_input:
  doAssert sumNatural(0, 5) == 5
  doAssert sumNatural(3, 7) == 10
  doAssert sumWithRedundantCheck(3, 7) == 10

block natural_rejects_negatives:
  let negVal = -1
  doAssertRaises(RangeDefect):
    discard callSumNatural(negVal)

block redundant_checks_are_dead_code:
  ## The manual checks never execute because the type boundary (Natural)
  ## rejects negatives first. The RangeDefect fires at parameter binding,
  ## not inside the proc body.
  doAssertRaises(RangeDefect):
    discard callSumRedundant(-1)

echo "C02: PASS"
