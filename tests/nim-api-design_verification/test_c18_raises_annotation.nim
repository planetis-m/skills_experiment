## C18: {.raises: [].} makes exception surface explicit and is enforced at compile time

# --- Test 1: proc marked {.raises: [].} that genuinely cannot raise compiles fine ---
proc addNoRaise(a, b: int): int {.raises: [].} =
  result = a + b

doAssert addNoRaise(3, 4) == 7, "raises:[] proc should compute correctly"

# --- Test 2: proc marked {.raises: [].} can call other {.raises: [].} procs ---
proc doubleNoRaise(x: int): int {.raises: [].} =
  addNoRaise(x, x)

doAssert doubleNoRaise(5) == 10, "raises:[] proc can call other raises:[] procs"

# --- Test 3: compiler enforces {.raises: [].} at compile time ---
static:
  doAssert not compiles(block:
    proc mayRaise(): int =
      if true: raise newException(ValueError, "boom")
      result = 42

    proc safeCall(): int {.raises: [].} =
      result = mayRaise()
  ), "compiler must reject raises:[] proc that calls a raising proc"

echo "C18: PASS"
