# Test: distinct_types.md reference compiles and works
type
  PackageId = distinct string
  UserId = distinct string

proc `==`*(a, b: PackageId): bool {.borrow.}
proc `$`*(id: PackageId): string {.borrow.}

proc `==`*(a, b: UserId): bool {.borrow.}
proc `$`*(id: UserId): string {.borrow.}

proc main =
  let pid = PackageId("nim")
  let uid = UserId("user1")

  # Borrowed == works within same type
  doAssert pid == PackageId("nim")
  doAssert uid == UserId("user1")

  # Borrowed $ works
  doAssert $pid == "nim"
  doAssert $uid == "user1"

  # Distinct types do not mix
  # pid == uid  # would not compile

main()
echo "ref_distinct_types: PASS"
