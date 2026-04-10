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
    pos: int

func isValidKey(s: string): bool =
  for c in s:
    if c notin {'a'..'z', '0'..'9', '-', '_'}:
      return false
  s.len > 0

func isValidValue(s: string): bool =
  for c in s:
    if c notin {'a'..'z', '0'..'9', '-', '_', '/'}:
      return false
  s.len > 0

func isComment(line: string): bool =
  line.len > 0 and line[0] == '#'

proc parseRule(line: string): tuple[key: string, value: string, ok: bool] =
  let eqPos = line.find('=')
  if eqPos < 0:
    return ("", "", false)
  let key = line[0 ..< eqPos].strip(chars = {' ', '\t'}).toLowerAscii()
  let value = line[eqPos + 1 ..^ 1].strip(chars = {' ', '\t'}).toLowerAscii()
  if isValidKey(key) and isValidValue(value):
    result = (key, value, true)

proc open*(p: var RuleParser; lines: openArray[string]; mode = pmStrict; label = "default") =
  p = RuleParser(mode: mode, label: label)
  p.lines = @lines

proc next*(p: var RuleParser): RuleEvent =
  if p.pos >= p.lines.len:
    return RuleEvent(kind: rekEof)

  let raw = p.lines[p.pos]
  inc p.pos
  let trimmed = raw.strip(chars = {' ', '\t'})

  if trimmed.len == 0:
    if p.mode == pmStrict:
      raise newException(ValueError, "empty line")
    inc p.skipped
    return RuleEvent(kind: rekSkip, reason: "empty")

  if isComment(trimmed):
    inc p.skipped
    return RuleEvent(kind: rekSkip, reason: "comment")

  let (key, value, ok) = parseRule(trimmed)
  if not ok:
    if p.mode == pmStrict:
      raise newException(ValueError, "invalid")
    inc p.rejected
    return RuleEvent(kind: rekReject, reason: "invalid")

  let normalized = key & "=" & value
  if normalized in p.accepted:
    inc p.duplicates
    return RuleEvent(kind: rekSkip, normalized: normalized, reason: "duplicate")

  p.accepted.add(normalized)
  RuleEvent(kind: rekAccept, normalized: normalized)

proc close*(p: var RuleParser) =
  p = RuleParser()

proc renderSummary*(p: RuleParser): seq[string] =
  result.add("summary " & p.label)
  result.add("mode " & (if p.mode == pmStrict: "strict" else: "lenient"))
  for a in p.accepted:
    result.add("accept " & a)
  result.add("duplicates " & $p.duplicates)
  result.add("skipped " & $p.skipped)
  result.add("rejected " & $p.rejected)

when isMainModule:
  var p: RuleParser

  # Lenient mode test
  p.open(@[" user = Alice ", " ", "#note", "user=alice", "bad!", "path = Docs/Guide"],
         mode = pmLenient, label = "batch-a")

  var events: seq[RuleEvent]
  for i in 0 ..< 7:
    events.add(p.next())

  assert events[0] == RuleEvent(kind: rekAccept, normalized: "user=alice")
  assert events[1] == RuleEvent(kind: rekSkip, reason: "empty")
  assert events[2] == RuleEvent(kind: rekSkip, reason: "comment")
  assert events[3] == RuleEvent(kind: rekSkip, normalized: "user=alice", reason: "duplicate")
  assert events[4] == RuleEvent(kind: rekReject, reason: "invalid")
  assert events[5] == RuleEvent(kind: rekAccept, normalized: "path=docs/guide")
  assert events[6] == RuleEvent(kind: rekEof)

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

  # Strict mode test
  p.open(@["bad!"], mode = pmStrict)
  try:
    discard p.next()
    assert false
  except ValueError:
    discard

  # Close test
  p.close()
  assert p.accepted.len == 0
  assert p.skipped == 0
  assert p.rejected == 0
  assert p.duplicates == 0
  assert p.mode == pmStrict
  assert p.label == "default"

  echo "SMOKE: PASS"
