## C06: Accessor errors through shared {.noinline, noreturn.} helper.

import std/strutils

type Data = object
  items: seq[string]

proc accessError(msg: string) {.noinline, noreturn.} =
  raise newException(ValueError, msg)

proc itemAt(d: Data; i: int): lent string =
  if i < 0 or i >= d.items.len: accessError("index out of bounds: " & $i)
  result = d.items[i]

proc nameAt(d: Data; i: int): lent string =
  if i < 0 or i >= d.items.len: accessError("index out of bounds: " & $i)
  result = d.items[i]

let d = Data(items: @["hello", "world"])
doAssert d.itemAt(0) == "hello"

# Both accessors produce identical error messages via shared helper
var msg1, msg2: string
try: discard d.itemAt(99)
except ValueError as e: msg1 = e.msg
try: discard d.nameAt(99)
except ValueError as e: msg2 = e.msg
doAssert msg1 == msg2
doAssert "index out of bounds" in msg1

echo "C06: PASS"
