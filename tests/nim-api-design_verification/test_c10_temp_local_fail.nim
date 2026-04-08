## C10 companion: this file demonstrates that a lent accessor using a
## temp local FAILS to compile under ORC due to escaping-borrow.
## This file is NOT meant to be compiled successfully.
## See test_c10_no_temp_locals.nim for the passing test.

type
  Data = object
    items: seq[string]

proc itemViaTemp(d: Data; i: int): lent string =
  let temp = d.items[i]   # temp is a copy
  result = temp            # ERROR: 'temp' escapes its stack frame

discard itemViaTemp(Data(items: @["test"]), 0)
