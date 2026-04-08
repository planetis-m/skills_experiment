## C18: "Mark procs that cannot raise with {.raises: [].} to make the exception
## surface explicit."

import std/assertions

block raises_empty_allows_nonraising:
  proc add(a, b: int): int {.raises: [].} =
    result = a + b
  doAssert add(3, 4) == 7, "non-raising proc with {.raises: [].} works"

block raises_empty_rejects_raising_calls:
  ## A proc marked {.raises: [].} that calls a raising proc fails to compile.
  proc mayRaise(): int =
    raise newException(ValueError, "boom")
  
  doAssert not compiles(
    block:
      proc bad(): int {.raises: [].} = mayRaise()
  ), "{.raises: [].} rejects calls to raising procs"

block raises_empty_allows_pure_ops:
  type Data = object
    x: int
    items: seq[int]

  proc getX(d: Data): int {.raises: [].} =
    result = d.x

  proc sumItems(d: Data): int {.raises: [].} =
    for i in d.items:
      result += i

  let d = Data(x: 42, items: @[1, 2, 3])
  doAssert getX(d) == 42
  doAssert sumItems(d) == 6

block raises_specific_enumerates:
  proc raiseValueError(): int {.raises: [ValueError].} =
    raise newException(ValueError, "expected")

  doAssert not compiles(
    block:
      proc bad(): int {.raises: [].} = raiseValueError()
  ), "{.raises: [].} rejects procs that raise ValueError"

  doAssert compiles(
    block:
      proc ok(): int {.raises: [ValueError].} = raiseValueError()
  ), "{.raises: [ValueError].} allows procs that raise ValueError"

echo "C18: PASS"
