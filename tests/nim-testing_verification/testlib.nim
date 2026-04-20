proc add*(a, b: int): int = a + b
proc greet*(name: string): string = "hello " & name
proc parseBad*(s: string): int =
  if s == "bad":
    raise newException(ValueError, "cannot parse: " & s)
  s.len
