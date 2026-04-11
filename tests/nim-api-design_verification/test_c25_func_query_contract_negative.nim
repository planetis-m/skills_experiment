## C25: a func used as a pure query contract must not perform side effects

var calls = 0

proc noteCall() =
  inc calls

func queryLen(s: string): int =
  noteCall()
  s.len

discard queryLen("abc")
