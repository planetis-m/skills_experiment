## C06: Accessor errors routed through shared {.noinline, noreturn.} helper

import std/strutils

type
  Container = object
    items: seq[string]

# --- Shared error helper ---
proc accessError*(msg: string): void {.noinline, noreturn.} =
  raise newException(ValueError, msg)

# --- Accessors using the shared helper ---
proc itemAt(c: Container; i: int): lent string =
  if i < 0 or i >= c.items.len:
    accessError("index out of bounds: " & $i)
  result = c.items[i]

proc nameAt(c: Container; i: int): lent string =
  if i < 0 or i >= c.items.len:
    accessError("index out of bounds: " & $i)
  result = c.items[i]

# --- Test 1: helper raises ValueError ---
block:
  let c = Container(items: @["alpha", "beta"])
  var caught = false
  try:
    discard c.itemAt(5)
  except ValueError as e:
    caught = true
    doAssert "index out of bounds" in e.msg,
      "Expected 'index out of bounds' in message, got: " & e.msg
  doAssert caught, "accessError did not raise ValueError"

# --- Test 2: consistent error messages across accessors ---
block:
  let c = Container(items: @["only"])
  var msg1, msg2: string
  try:
    discard c.itemAt(99)
  except ValueError as e:
    msg1 = e.msg
  try:
    discard c.nameAt(99)
  except ValueError as e:
    msg2 = e.msg
  doAssert msg1 == msg2,
    "Inconsistent messages: '" & msg1 & "' vs '" & msg2 & "'"

# --- Test 3: noreturn — helper never returns normally ---
block:
  # If the helper returned normally, the code after the call would execute.
  # We verify that code after accessError is unreachable by checking the
  # exception propagates out of the block.
  let c = Container(items: @[])
  var reachedPastCall = false
  try:
    discard c.itemAt(0)
    reachedPastCall = true   # should never execute
  except ValueError:
    discard
  doAssert not reachedPastCall,
    "accessError returned — noreturn contract violated"

# --- Test 4: valid accessor calls still work ---
block:
  let c = Container(items: @["hello", "world"])
  doAssert c.itemAt(0) == "hello"
  doAssert c.nameAt(1) == "world"

echo "C06: PASS"
