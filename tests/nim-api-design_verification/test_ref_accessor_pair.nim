# Test: accessor_pair.md reference compiles and works
type
  PackageMeta = object
    version: string
    tags: seq[string]

  PackageCatalog = object
    ids: seq[string]
    entries: seq[PackageMeta]

proc raiseAccessorError(msg: string) {.noinline, noreturn.} =
  raise newException(KeyError, msg)

proc findIndex(catalog: PackageCatalog; id: string): int {.inline.} =
  for i, existing in catalog.ids:
    if existing == id:
      return i
  raiseAccessorError("unknown package id: " & id)

proc meta*(catalog: PackageCatalog; id: string): lent PackageMeta
    {.inline, raises: [KeyError].} =
  result = catalog.entries[findIndex(catalog, id)]

proc tags*(catalog: PackageCatalog; id: string): lent seq[string]
    {.inline, raises: [KeyError].} =
  result = catalog.entries[findIndex(catalog, id)].tags

proc tags*(catalog: var PackageCatalog; id: string): var seq[string]
    {.inline, raises: [KeyError].} =
  result = catalog.entries[findIndex(catalog, id)].tags

proc main =
  var cat = PackageCatalog(
    ids: @["nim", "jester"],
    entries: @[
      PackageMeta(version: "2.0", tags: @["lang"]),
      PackageMeta(version: "0.5", tags: @["web"])
    ]
  )

  # lent accessor
  doAssert meta(cat, "nim").version == "2.0"

  # lent tags accessor
  doAssert tags(cat, "jester").len == 1

  # var tags accessor
  tags(cat, "nim").add("compiler")
  doAssert tags(cat, "nim").len == 2

  # missing id raises KeyError
  var caught = false
  try:
    discard meta(cat, "missing")
  except KeyError:
    caught = true
  doAssert caught

main()
echo "ref_accessor_pair: PASS"
