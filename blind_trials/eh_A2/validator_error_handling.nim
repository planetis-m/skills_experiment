# Validator for error handling benchmark
# Tests error handling correctness — not simulation specifics.

import std/[strutils, sequtils]

import ./subject_solution

proc main() =
  echo "=== Test 1: loadDocument raises on empty path ==="
  var caught = false
  try:
    discard loadDocument("")
  except IOError:
    caught = true
    doAssert getCurrentExceptionMsg().len > 0
  doAssert caught, "loadDocument('') should raise IOError"
  echo "PASS"

  echo "=== Test 2: loadDocument returns a Document for valid path ==="
  let doc2 = loadDocument("test_path")
  discard doc2  # just verifying no exception
  echo "PASS"

  echo "=== Test 3: renderPage raises on out-of-bounds ==="
  let doc = Document(title: "test", pages: @["page1"])
  caught = false
  try:
    discard renderPage(doc, 5)
  except ValueError:
    caught = true
  doAssert caught, "renderPage with out-of-bounds index should raise ValueError"
  echo "PASS"

  echo "=== Test 4: convertDocument propagates errors ==="
  caught = false
  try:
    discard convertDocument("", "pdf")
  except IOError:
    caught = true
  doAssert caught, "convertDocument should propagate IOError from loadDocument"
  echo "PASS"

  echo "=== Test 5: runBatch catches at boundary, no exceptions escape ==="
  let results = runBatch(@["", "valid_path"], "pdf")
  doAssert results.len == 2, "runBatch should return one result per path"
  doAssert not results[0].success, "Empty path should fail"
  doAssert results[0].errorMsg.len > 0, "Error message should not be empty"
  # Second result may succeed or fail depending on simulation, but must not crash
  echo "PASS"

  echo "=== Test 6: tryParseInt returns bool ==="
  var val: int
  doAssert tryParseInt("42", val), "Valid int should return true"
  doAssert val == 42
  doAssert not tryParseInt("abc", val), "Invalid int should return false"
  doAssert not tryParseInt("", val), "Empty string should return false"
  echo "PASS"

  echo "=== Test 7: translateError re-raises as IOError ==="
  caught = false
  try:
    translateError()
  except IOError:
    caught = true
    let msg = getCurrentExceptionMsg()
    doAssert msg.contains("translation failed"), "Should contain context: " & msg
  except CatchableError:
    doAssert false, "Should re-raise as IOError, got: " & $getCurrentException().name
  doAssert caught, "translateError should raise IOError"
  echo "PASS"

  echo ""
  echo "=== ALL TESTS PASSED ==="

main()
