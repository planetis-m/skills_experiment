import std/strutils

type
  ParseMode* = enum
    pmStrict,
    pmLenient

  RuleEventKind* = enum
    rekEof,
    rekAccept,
    rekSkip,
    rekReject

  RuleEvent* = object
    kind*: RuleEventKind
    normalized*: string
    reason*: string = ""

  RuleParser* = object
    mode*: ParseMode = pmStrict
    label*: string = "default"
    accepted*: seq[string]
    skipped*: int
    rejected*: int
    duplicates*: int
    lines: seq[string]
    cursor: int

const
  keyChars = {'a'..'z', '0'..'9', '-', '_'}
  valChars = {'a'..'z', '0'..'9', '-', '_', '/'}

func validChars(s: string; allowed: set[char]): bool =
  for c in s:
    if c notin allowed: return false
  true

proc open*(p: var RuleParser; lines: openArray[string]; mode = pmStrict; label = "default") =
  p = RuleParser(mode: mode, label: label)
  p.lines = @lines

proc next*(p: var RuleParser): RuleEvent =
  if p.cursor >= p.lines.len:
    return RuleEvent(kind: rekEof)

  let raw = p.lines[p.cursor]
  inc p.cursor
  let line = raw.strip(leading = true, trailing = true, chars = {' ', '\t'})

  if line.len == 0:
    if p.mode == pmStrict:
      raise newException(ValueError, "empty line")
    inc p.skipped
    return RuleEvent(kind: rekSkip, reason: "empty")

  if line[0] == '#':
    inc p.skipped
    return RuleEvent(kind: rekSkip, reason: "comment")

  let eqPos = line.find('=')
  if eqPos < 0:
    if p.mode == pmStrict:
      raise newException(ValueError, "malformed line")
    inc p.rejected
    return RuleEvent(kind: rekReject, reason: "invalid")

  let rawKey = line[0 ..< eqPos].strip(leading = true, trailing = true, chars = {' ', '\t'})
  let rawVal = line[eqPos + 1 ..^ 1].strip(leading = true, trailing = true, chars = {' ', '\t'})
  let key = rawKey.toLowerAscii()
  let val = rawVal.toLowerAscii()

  if key.len == 0 or val.len == 0 or not validChars(key, keyChars) or not validChars(val, valChars):
    if p.mode == pmStrict:
      raise newException(ValueError, "invalid rule")
    inc p.rejected
    return RuleEvent(kind: rekReject, reason: "invalid")

  let normalized = key & "=" & val

  if normalized in p.accepted:
    inc p.duplicates
    return RuleEvent(kind: rekSkip, normalized: normalized, reason: "duplicate")

  p.accepted.add(normalized)
  RuleEvent(kind: rekAccept, normalized: normalized)

proc close*(p: var RuleParser) =
  p = RuleParser()

proc renderSummary*(p: RuleParser): seq[string] =
  result = @[
    "summary " & p.label,
    "mode " & (if p.mode == pmStrict: "strict" else: "lenient")
  ]
  for a in p.accepted:
    result.add("accept " & a)
  result.add("duplicates " & $p.duplicates)
  result.add("skipped " & $p.skipped)
  result.add("rejected " & $p.rejected)

when isMainModule:
  var p: RuleParser
  p.open(@[" user = Alice ", " ", "#note", "user=alice", "bad!", "path = Docs/Guide"],
         mode = pmLenient, label = "batch-a")

  let expected = @[
    RuleEvent(kind: rekAccept, normalized: "user=alice"),
    RuleEvent(kind: rekSkip, reason: "empty"),
    RuleEvent(kind: rekSkip, reason: "comment"),
    RuleEvent(kind: rekSkip, normalized: "user=alice", reason: "duplicate"),
    RuleEvent(kind: rekReject, reason: "invalid"),
    RuleEvent(kind: rekAccept, normalized: "path=docs/guide"),
    RuleEvent(kind: rekEof)
  ]

  for i, exp in expected:
    let got = p.next()
    assert got.kind == exp.kind, $i
    assert got.normalized == exp.normalized, $i
    assert got.reason == exp.reason, $i

  assert p.accepted == @["user=alice", "path=docs/guide"]
  assert p.skipped == 2
  assert p.duplicates == 1
  assert p.rejected == 1

  let summary = p.renderSummary()
  assert summary == @[
    "summary batch-a", "mode lenient",
    "accept user=alice", "accept path=docs/guide",
    "duplicates 1", "skipped 2", "rejected 1"
  ]

  # strict mode raises ValueError
  p.open(@["bad!"])
  try:
    discard p.next()
    assert false
  except ValueError:
    discard

  # close resets
  p.close()
  assert p.accepted.len == 0
  assert p.skipped == 0
  assert p.rejected == 0
  assert p.duplicates == 0
  assert p.mode == pmStrict
  assert p.label == "default"

  echo "SMOKE: PASS"
