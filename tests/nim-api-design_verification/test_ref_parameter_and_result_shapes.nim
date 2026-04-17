# Test: parameter_and_result_shapes.md reference compiles and works
type
  WalkOptions = object
    relative*: bool
    skipHidden*: bool
    extension*: string
    maxDepth*: int

  SearchSummary = object
    root*: string
    matchedPaths*: seq[string]
    skippedCount*: int

proc toWalkOptions*(extension = ".nim", relative = false, skipHidden = false,
    maxDepth: Natural = 0): WalkOptions =
  WalkOptions(
    relative: relative,
    skipHidden: skipHidden,
    extension: extension,
    maxDepth: maxDepth
  )

proc findFiles*(root: string; options = toWalkOptions()): SearchSummary {.raises: [ValueError].} =
  if root.len == 0:
    raise newException(ValueError, "root is empty")

  result = SearchSummary(
    root: root,
    matchedPaths: @["src/app.nim", "tests/app_test.nim"],
    skippedCount: 0
  )

proc main =
  # Default options
  let s1 = findFiles("src")
  doAssert s1.root == "src"
  doAssert s1.matchedPaths.len == 2
  doAssert s1.skippedCount == 0

  # Custom options
  let opts = toWalkOptions(extension = ".txt", skipHidden = true, maxDepth = 5)
  doAssert opts.extension == ".txt"
  doAssert opts.skipHidden
  doAssert opts.maxDepth == 5

  let s2 = findFiles("lib", opts)
  doAssert s2.root == "lib"

  # Empty root raises ValueError
  var caught = false
  try:
    discard findFiles("")
  except ValueError:
    caught = true
  doAssert caught

main()
echo "ref_parameter_and_result_shapes: PASS"
