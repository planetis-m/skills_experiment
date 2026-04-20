proc inner() =
  raise newException(ValueError, "test error")

proc outer() =
  inner()

proc main() =
  outer()

main()
