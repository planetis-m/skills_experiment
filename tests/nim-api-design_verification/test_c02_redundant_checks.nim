## C02: Redundant runtime checks that restate existing type or proc contracts
##      should not be added unless required by a boundary.

import std/assertions

# --- Proc with Natural parameter: already prevents negatives ---
proc sumNatural(a: Natural, b: Natural): int {.inline.} =
  result = a + b

# --- Version with redundant check (what the claim says NOT to do) ---
proc sumNaturalWithRedundantCheck(a: Natural, b: Natural): int =
  # This check is dead code — Natural already guarantees a >= 0 and b >= 0
  if a < 0:
    raise newException(ValueError, "a is negative")  # unreachable
  if b < 0:
    raise newException(ValueError, "b is negative")  # unreachable
  result = a + b

# Helper to pass a negative value through Natural boundary at runtime
proc callSumNatural(n: int): int {.inline.} =
  sumNatural(n, n)

proc callSumNaturalRedundant(n: int): int {.inline.} =
  sumNaturalWithRedundantCheck(n, n)

proc main() =
  # ---- Valid inputs work ----
  doAssert sumNatural(0, 5) == 5
  doAssert sumNatural(3, 7) == 10
  doAssert sumNaturalWithRedundantCheck(3, 7) == 10

  # ---- Natural already rejects negatives via RangeDefect ----
  let negVal = -1
  doAssertRaises(RangeDefect):
    discard callSumNatural(negVal)

  # ---- The redundant checks inside sumNaturalWithRedundantCheck are
  #      dead code because the type boundary already rejected negatives.
  #      The exception fires at the parameter binding (Natural conversion),
  #      never inside the proc body where the manual checks live. ----
  doAssertRaises(RangeDefect):
    discard callSumNaturalRedundant(negVal)

  echo "C02: PASS"

main()
