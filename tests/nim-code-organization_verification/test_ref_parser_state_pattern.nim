# Test: parser_state_pattern.md reference compiles and works
type
  WriteState = object
    nextToWrite: int
    ready: seq[bool]
    writtenIds: seq[string]

proc markReady(state: var WriteState; idx: int) =
  state.ready[idx] = true

proc flushReady(state: var WriteState; ids: openArray[string]) =
  while state.nextToWrite < ids.len and state.ready[state.nextToWrite]:
    state.writtenIds.add ids[state.nextToWrite]
    inc state.nextToWrite

proc run(ids: openArray[string], completionOrder: openArray[int]): seq[string] =
  var state = WriteState(
    nextToWrite: 0,
    ready: newSeq[bool](ids.len),
    writtenIds: @[]
  )

  for idx in completionOrder:
    markReady(state, idx)
    flushReady(state, ids)

  result = state.writtenIds

proc main =
  # Items complete in order 2, 0, 1
  # After 2: nothing flushed (0 not ready)
  # After 0: flush 0, then stop (1 not ready)
  # After 1: flush 1, then flush 2
  let result = run(["a", "b", "c"], [2, 0, 1])
  doAssert result == @["a", "b", "c"]

  # Items complete in order 1, 0, 2
  # After 1: nothing (0 not ready)
  # After 0: flush 0, flush 1
  # After 2: flush 2
  let result2 = run(["x", "y", "z"], [1, 0, 2])
  doAssert result2 == @["x", "y", "z"]

  # Items complete in order 0, 1, 2 (sequential)
  let result3 = run(["p", "q", "r"], [0, 1, 2])
  doAssert result3 == @["p", "q", "r"]

main()
echo "ref_parser_state_pattern: PASS"
