## C06: Accessor errors routed through shared {.noinline, noreturn.} helper.

import std/strutils

type
  Container = object
    items: seq[string]

proc accessError(msg: string) {.noinline, noreturn.} =
  raise newException(ValueError, msg)

proc itemAt(c: Container; i: int): lent string =
  if i < 0 or i >= c.items.len:
    accessError("index out of bounds: " & $i)
  result = c.items[i]

proc nameAt(c: Container; i: int): lent string =
  if i < 0 or i >= c.items.len:
    accessError("index out of bounds: " & $i)
  result = c.items[i]

block helper_raises_valueerror:
  let c = Container(items: @["alpha", "beta"])
  var caught = false
  try:
    discard c.itemAt(5)
  except ValueError as e:
    caught = true
    doAssert "index out of bounds" in e.msg
  doAssert caught

block consistent_messages_across_accessors:
  let c = Container(items: @["only"])
  var msg1, msg2: string
  try: discard c.itemAt(99)
  except ValueError as e: msg1 = e.msg
  try: discard c.nameAt(99)
  except ValueError as e: msg2 = e.msg
  doAssert msg1 == msg2, "Inconsistent: '" & msg1 & "' vs '" & msg2 & "'"

block noreturn_never_returns:
  let c = Container(items: @[])
  var reachedPastCall = false
  try:
    discard c.itemAt(0)
    reachedPastCall = true
  except ValueError:
    discard
  doAssert not reachedPastCall, "accessError returned — noreturn violated"

block valid_calls_still_work:
  let c = Container(items: @["hello", "world"])
  doAssert c.itemAt(0) == "hello"
  doAssert c.nameAt(1) == "world"

echo "C06: PASS"
