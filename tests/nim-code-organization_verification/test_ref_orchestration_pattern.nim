# Test: orchestration_pattern.md reference compiles and works
# Tests both the preferred explicit-state pattern and the nested closure pattern

# --- Preferred: explicit state object ---
type
  WriteState = object
    nextToWrite: int

proc flushReady(state: var WriteState; total: int) =
  if state.nextToWrite < total:
    inc state.nextToWrite

proc testExplicitState =
  var state = WriteState(nextToWrite: 0)
  flushReady(state, 5)
  doAssert state.nextToWrite == 1
  flushReady(state, 5)
  flushReady(state, 5)
  flushReady(state, 5)
  flushReady(state, 5)
  doAssert state.nextToWrite == 5
  # Already at total, no further increment
  flushReady(state, 5)
  doAssert state.nextToWrite == 5

# --- Nested closure pattern (design smell but works) ---
proc testNestedClosure =
  let total = 10
  var nextToWrite = 0
  proc flushReady() =
    if nextToWrite < total:
      inc nextToWrite
  flushReady()
  doAssert nextToWrite == 1
  for i in 0..<9:
    flushReady()
  doAssert nextToWrite == 10
  flushReady()
  doAssert nextToWrite == 10

testExplicitState()
testNestedClosure()
echo "ref_orchestration_pattern: PASS"
