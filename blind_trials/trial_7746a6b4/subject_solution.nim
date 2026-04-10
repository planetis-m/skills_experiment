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

proc isValidKey(s: string): bool =
  for c in s:
    if c notin {'a'..'z', '0'..'9', '-', '_'}:
      return false
  result = s.len > 0

proc isValidValue(s: string): bool =
  for c in s:
    if c notin {'a'..'z', '0'..'9', '-', '_', '/'}:
      return false
  result = s.len > 0

proc open*(p: var RuleParser; lines: openArray[string]; mode = pmStrict;
    label = "default") =
  p = RuleParser(mode: mode, label: label,
    lines: @lines, pos: 0)

proc next*(p: var RuleParser): RuleEvent =
  if p.pos >= p.lines.len:
    return RuleEvent(kind: rekEof)

  let trimmed = p.lines[p.pos].strip(chars = Whitespace - {'\n', '\r'})
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
  if eqPos < 0 or eqPos != trimmed.rfind('='):
    if p.mode == pmStrict:
      raise newException(ValueError, "invalid")
    inc p.rejected
    return RuleEvent(kind: rekReject, reason: "invalid")

  let rawKey = trimmed[0..<eqPos].strip(chars = {' ', '\t'})
  let rawVal = trimmed[eqPos + 1..^1].strip(chars = {' ', '\t'})
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
  RuleEvent(kind: rekAccept, normalized: normalized)

proc close*(p: var RuleParser) =
  p = RuleParser()

proc renderSummary*(p: RuleParser): seq[string] =
  let modeStr = if p.mode == pmStrict: "strict" else: "lenient"
  result = @["summary " & p.label, "mode " & modeStr]
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

    let e1 = p.next()
    assert e1 == RuleEvent(kind: rekAccept, normalized: "user=alice")

    let e2 = p.next()
    assert e2 == RuleEvent(kind: rekSkip, reason: "empty")

    let e3 = p.next()
    assert e3 == RuleEvent(kind: rekSkip, reason: "comment")

    let e4 = p.next()
    assert e4 == RuleEvent(kind: rekSkip, normalized: "user=alice", reason: "duplicate")

    let e5 = p.next()
    assert e5 == RuleEvent(kind: rekReject, reason: "invalid")

    let e6 = p.next()
    assert e6 == RuleEvent(kind: rekAccept, normalized: "path=docs/guide")

    let e7 = p.next()
    assert e7 == RuleEvent(kind: rekEof)

    assert p.accepted == @["user=alice", "path=docs/guide"]
    assert p.skipped == 2
    assert p.duplicates == 1
    assert p.rejected == 1

    let summary = p.renderSummary()
    assert summary == @["summary batch-a", "mode lenient",
      "accept user=alice", "accept path=docs/guide",
      "duplicates 1", "skipped 2", "rejected 1"]

  block:
    var p: RuleParser
    p.open(@["bad!"])
    var raised = false
    try:
      discard p.next()
    except ValueError:
      raised = true
    assert raised

  block:
    var p: RuleParser
    p.open(@["user=alice"], mode = pmLenient, label = "test")
    discard p.next()
    p.close()
    assert p.accepted.len == 0
    assert p.skipped == 0
    assert p.rejected == 0
    assert p.duplicates == 0
    assert p.mode == pmStrict
    assert p.label == "default"

  echo "SMOKE: PASS"
