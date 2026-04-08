## C01: Type-level contracts (Positive) should be relied upon;
##      weakening to int + manual checks is incorrect/lossy.

# --- Strong contract version: uses Positive ---
proc doubleStrong(n: Positive): int {.inline.} =
  result = n * 2

# --- Weakened version: int + manual check ---
proc doubleWeak(n: int): int =
  if n <= 0:
    return 0  # silently swallows bad input — lossy!
  result = n * 2

# Helper: tries to call doubleStrong with any int, forcing range check
proc callDoubleStrong(n: int): int {.inline.} =
  doubleStrong(n)

proc main() =
  # ---- Positive tests: valid input works for both ----
  doAssert doubleStrong(1) == 2
  doAssert doubleStrong(5) == 10
  doAssert doubleWeak(5) == 10

  # ---- Show weakening is lossy ----
  # The weakened version silently returns 0 for negative input
  # instead of raising — this is the "lossy" behavior.
  doAssert doubleWeak(-1) == 0   # silently swallows bad input!
  doAssert doubleWeak(-5) == 0   # silently swallows bad input!

  # ---- Strong version catches bad input via type-level contract ----
  # Passing a negative int where Positive is expected triggers RangeDefect.
  # We use a helper proc so Nim doesn't constant-fold at the call site.
  doAssertRaises(RangeDefect):
    discard callDoubleStrong(-1)

  echo "C01: PASS"

main()
