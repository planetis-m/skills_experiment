## C08: func bodies are checked for side effects

var calls = 0

proc noteCall() =
  inc calls

func countText(s: string): int =
  noteCall()
  s.len

discard countText("abc")
