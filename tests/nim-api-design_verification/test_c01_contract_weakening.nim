## C01: Type-level contracts (Positive) should be relied upon;
##      weakening to int + manual checks is lossy/incorrect.

proc doubleStrong(n: Positive): int {.inline.} =
  result = n * 2

proc doubleWeak(n: int): int =
  if n <= 0:
    return 0  # silently swallows bad input
  result = n * 2

proc callDoubleStrong(n: int): int {.inline.} =
  doubleStrong(n)

block valid_input:
  doAssert doubleStrong(1) == 2
  doAssert doubleStrong(5) == 10
  doAssert doubleWeak(5) == 10

block weakening_is_lossy:
  ## The weakened version silently returns 0 for negative input
  ## instead of raising — this is the lossy behavior.
  doAssert doubleWeak(-1) == 0
  doAssert doubleWeak(-5) == 0

block strong_contract_catches_bad_input:
  ## Passing a negative int where Positive is expected triggers RangeDefect.
  ## We use a helper proc so Nim doesn't constant-fold at the call site.
  doAssertRaises(RangeDefect):
    discard callDoubleStrong(-1)

echo "C01: PASS"
