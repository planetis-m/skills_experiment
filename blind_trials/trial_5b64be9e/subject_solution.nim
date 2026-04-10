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
    lines*: seq[string]
    pos*: int

proc open*(p: var RuleParser; lines: openArray[string]; mode = pmStrict; label = "default") =
  p = default(RuleParser)
  p.mode = mode
  p.label = label
  p.lines = @lines

proc isValidKey(s: string): bool =
  if s.len == 0: return false
  for c in s:
    if c notin {'a'..'z', '0'..'9', '-', '_'}: return false
  true

proc isValidValue(s: string): bool =
  if s.len == 0: return false
  for c in s:
    if c notin {'a'..'z', '0'..'9', '-', '_', '/'}: return false
  true

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

  if trimmed[0] == '#':
    inc p.skipped
    return RuleEvent(kind: rekSkip, reason: "comment")

  let eqPos = trimmed.find('=')
  if eqPos < 0 or trimmed.find('=', eqPos + 1) >= 0:
    if p.mode == pmStrict:
      raise newException(ValueError, "invalid")
    inc p.rejected
    return RuleEvent(kind: rekReject, reason: "invalid")

  let key = trimmed[0 ..< eqPos].strip(chars = {' ', '\t'}).toLowerAscii()
  let value = trimmed[eqPos + 1 ..^ 1].strip(chars = {' ', '\t'}).toLowerAscii()

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
  p = default(RuleParser)

proc renderSummary*(p: RuleParser): seq[string] =
  result.add("summary " & p.label)
  result.add("mode " & (if p.mode == pmStrict: "strict" else: "lenient"))
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
    try:
      discard p.next()
      assert false
    except ValueError:
      discard

  block:
    var p: RuleParser
    p.open(@["bad!"], mode = pmLenient, label = "x")
    discard p.next()
    p.close()
    assert p.accepted.len == 0
    assert p.skipped == 0
    assert p.rejected == 0
    assert p.duplicates == 0
    assert p.mode == pmStrict
    assert p.label == "default"

  echo "SMOKE: PASS"
