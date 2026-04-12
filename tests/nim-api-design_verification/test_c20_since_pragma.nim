## C20: user code should use when-guards; {.since.} is stdlib-internal

when (NimMajor, NimMinor) >= (2, 0):
  proc currentApi(): string =
    "available"
else:
  proc currentApi(): string =
    "fallback"

doAssert currentApi() == "available"

static:
  doAssert not compiles(block:
    proc userApi(): int {.since: (1, 1).} =
      99

    discard userApi()
  ), "compiler must reject {.since.} in user code"

echo "C20: PASS"
