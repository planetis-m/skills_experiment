# Test: collection_accessors.md reference compiles and works
type
  PackageId = distinct string

  PackageMeta = object
    title: string
    version: string
    tags: seq[string]
    downloads: Natural

  PackageCatalog = object
    ids: seq[PackageId]
    entries: seq[PackageMeta]

proc `==`(a, b: PackageId): bool {.borrow.}
proc `$`(id: PackageId): string {.borrow.}

proc raiseMissingPackage(id: PackageId) {.noinline, noreturn.} =
  raise newException(KeyError, "unknown package: " & $id)

proc initPackageCatalog(initialSize = 8): PackageCatalog =
  PackageCatalog(
    ids: newSeqOfCap[PackageId](initialSize),
    entries: newSeqOfCap[PackageMeta](initialSize)
  )

proc toPackageCatalog(pairs: openArray[(PackageId, PackageMeta)]): PackageCatalog =
  result = initPackageCatalog(pairs.len)
  for (id, meta) in pairs:
    result.ids.add id
    result.entries.add meta

proc findIndex(catalog: PackageCatalog; id: PackageId): int {.inline.} =
  for i, existing in catalog.ids:
    if existing == id:
      return i
  raiseMissingPackage(id)

proc len(catalog: PackageCatalog): int {.inline.} =
  catalog.ids.len

proc meta(catalog: PackageCatalog; id: PackageId): lent PackageMeta {.inline.} =
  result = catalog.entries[findIndex(catalog, id)]

proc tags(catalog: PackageCatalog; id: PackageId): lent seq[string] {.inline.} =
  result = catalog.entries[findIndex(catalog, id)].tags

proc tags(catalog: var PackageCatalog; id: PackageId): var seq[string] {.inline.} =
  result = catalog.entries[findIndex(catalog, id)].tags

proc downloads(catalog: PackageCatalog; id: PackageId): Natural {.inline.} =
  catalog.entries[findIndex(catalog, id)].downloads

proc main =
  var cat = toPackageCatalog({
    PackageId("nim"): PackageMeta(title: "Nim", version: "2.0", tags: @["lang"], downloads: 1000),
    PackageId("jester"): PackageMeta(title: "Jester", version: "0.5", tags: @["web"], downloads: 500)
  })

  doAssert len(cat) == 2
  doAssert meta(cat, PackageId("nim")).title == "Nim"
  doAssert meta(cat, PackageId("jester")).version == "0.5"

  # lent accessor works
  doAssert tags(cat, PackageId("nim")).len == 1

  # var accessor allows mutation
  tags(cat, PackageId("nim")).add("compiler")
  doAssert tags(cat, PackageId("nim")).len == 2

  # scalar accessor
  doAssert downloads(cat, PackageId("nim")) == 1000

  # missing id raises KeyError
  var caught = false
  try:
    discard meta(cat, PackageId("missing"))
  except KeyError:
    caught = true
  doAssert caught

main()
echo "ref_collection_accessors: PASS"
