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

proc open*(p: var RuleParser; lines: openArray[string]; mode = pmStrict; label = "default") =
  p = RuleParser(mode: mode, label: label)
  p.lines = @lines

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

proc next*(p: var RuleParser): RuleEvent =
  if p.pos >= p.lines.len:
    return RuleEvent(kind: rekEof)
  let trimmed = p.lines[p.pos].strip(leading = true, trailing = true, chars = {' ', '\t'})
  inc p.pos
  if trimmed.len == 0:
    if p.mode == pmStrict:
      raise newException(ValueError, "empty line")
    inc p.skipped
    return RuleEvent(kind: rekSkip, reason: "empty")
  if trimmed[0] == '#':
    inc p.skipped
    return RuleEvent(kind: rekSkip, reason: "comment")
  let eqPos = trimmed.find('=')
  if eqPos < 0:
    if p.mode == pmStrict:
      raise newException(ValueError, "invalid")
    inc p.rejected
    return RuleEvent(kind: rekReject, reason: "invalid")
  let rawKey = trimmed[0..<eqPos].strip(chars = {' ', '\t'})
  let rawVal = trimmed[eqPos+1..^1].strip(chars = {' ', '\t'})
  let key = rawKey.toLowerAscii()
  let value = rawVal.toLowerAscii()
  if not isValidKey(key) or not isValidValue(value):
    if p.mode == pmStrict:
      raise newException(ValueError, "invalid")
    inc p.rejected
    return RuleEvent(kind: rekReject, reason: "invalid")
  let normalized = key & "=" & value
  if normalized in p.accepted:
    inc p.duplicates
    return RuleEvent(kind: rekSkip, normalized: normalized, reason: "duplicate")
  p.accepted.add(normalized)
  return RuleEvent(kind: rekAccept, normalized: normalized)

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
  block:
    var p: RuleParser
    p.open(@[" user = Alice ", " ", "#note", "user=alice", "bad!", "path = Docs/Guide"],
           mode = pmLenient, label = "batch-a")
    var events: seq[RuleEvent]
    for i in 0..<7:
      events.add(p.next())
    doAssert events[0] == RuleEvent(kind: rekAccept, normalized: "user=alice")
    doAssert events[1] == RuleEvent(kind: rekSkip, reason: "empty")
    doAssert events[2] == RuleEvent(kind: rekSkip, reason: "comment")
    doAssert events[3] == RuleEvent(kind: rekSkip, normalized: "user=alice", reason: "duplicate")
    doAssert events[4] == RuleEvent(kind: rekReject, reason: "invalid")
    doAssert events[5] == RuleEvent(kind: rekAccept, normalized: "path=docs/guide")
    doAssert events[6] == RuleEvent(kind: rekEof)
    doAssert p.accepted == @["user=alice", "path=docs/guide"]
    doAssert p.skipped == 2
    doAssert p.duplicates == 1
    doAssert p.rejected == 1
    doAssert p.renderSummary() == @[
      "summary batch-a", "mode lenient",
      "accept user=alice", "accept path=docs/guide",
      "duplicates 1", "skipped 2", "rejected 1"]
  block:
    var p: RuleParser
    p.open(@["bad!"], mode = pmStrict)
    try:
      discard p.next()
      doAssert false
    except ValueError:
      discard
  block:
    var p: RuleParser
    p.open(@["x=y"], mode = pmLenient, label = "t")
    discard p.next()
    p.close()
    doAssert p.accepted.len == 0
    doAssert p.skipped == 0
    doAssert p.rejected == 0
    doAssert p.duplicates == 0
    doAssert p.mode == pmStrict
    doAssert p.label == "default"
  echo "SMOKE: PASS"
