# Test: constructors.md reference compiles and works
type
  Catalog = object
    items: seq[string]

proc initCatalog(initialSize = 8): Catalog =
  Catalog(items: newSeqOfCap[string](initialSize))

proc toCatalog(items: openArray[string]): Catalog =
  result = initCatalog(items.len)
  for item in items:
    result.items.add item

proc toCatalog(item: string): Catalog =
  result = initCatalog(1)
  result.items.add item

type
  CatalogRef = ref Catalog

proc newCatalog(initialSize = 8): CatalogRef =
  new(result)
  result[] = initCatalog(initialSize)

proc main =
  # Value type constructor
  var c1 = initCatalog()
  doAssert c1.items.len == 0

  # Conversion from openArray
  var c2 = toCatalog(["a", "b", "c"])
  doAssert c2.items.len == 3
  doAssert c2.items[0] == "a"

  # Conversion from single string
  var c3 = toCatalog("single")
  doAssert c3.items.len == 1
  doAssert c3.items[0] == "single"

  # Ref wrapper reuses value-type init
  var r = newCatalog(4)
  doAssert r.items.len == 0

main()
echo "ref_constructors: PASS"
