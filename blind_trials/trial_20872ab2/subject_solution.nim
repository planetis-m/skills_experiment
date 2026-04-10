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

func trimLine(s: string): string =
  s.strip(leading = true, trailing = true, chars = {' ', '\t'})

proc open*(p: var RuleParser; lines: openArray[string]; mode = pmStrict;
    label = "default") =
  p = RuleParser(mode: mode, label: label)
  p.lines = @lines

proc next*(p: var RuleParser): RuleEvent =
  if p.pos >= p.lines.len:
    return RuleEvent(kind: rekEof)

  let raw = p.lines[p.pos]
  inc p.pos
  let trimmed = raw.trimLine()

  if trimmed.len == 0:
    if p.mode == pmStrict:
      raise newException(ValueError, "empty line")
    inc p.skipped
    return RuleEvent(kind: rekSkip, reason: "empty")

  if trimmed[0] == '#':
    inc p.skipped
    return RuleEvent(kind: rekSkip, reason: "comment")

  if count(trimmed, '=') != 1:
    if p.mode == pmStrict:
      raise newException(ValueError, "invalid")
    inc p.rejected
    return RuleEvent(kind: rekReject, reason: "invalid")

  let parts = trimmed.split('=', maxsplit = 1)
  let key = parts[0].trimLine().toLowerAscii()
  let val = parts[1].trimLine().toLowerAscii()

  if not isValidKey(key) or not isValidValue(val):
    if p.mode == pmStrict:
      raise newException(ValueError, "invalid")
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
  block:
    var p: RuleParser
    p.open(@[" user = Alice ", " ", "#note", "user=alice", "bad!", "path = Docs/Guide"],
      mode = pmLenient, label = "batch-a")

    let e1 = p.next()
    doAssert e1 == RuleEvent(kind: rekAccept, normalized: "user=alice")

    let e2 = p.next()
    doAssert e2 == RuleEvent(kind: rekSkip, reason: "empty")

    let e3 = p.next()
    doAssert e3 == RuleEvent(kind: rekSkip, reason: "comment")

    let e4 = p.next()
    doAssert e4 == RuleEvent(kind: rekSkip, normalized: "user=alice", reason: "duplicate")

    let e5 = p.next()
    doAssert e5 == RuleEvent(kind: rekReject, reason: "invalid")

    let e6 = p.next()
    doAssert e6 == RuleEvent(kind: rekAccept, normalized: "path=docs/guide")

    let e7 = p.next()
    doAssert e7 == RuleEvent(kind: rekEof)

    doAssert p.accepted == @["user=alice", "path=docs/guide"]
    doAssert p.skipped == 2
    doAssert p.duplicates == 1
    doAssert p.rejected == 1

    let summary = p.renderSummary()
    doAssert summary == @[
      "summary batch-a", "mode lenient", "accept user=alice",
      "accept path=docs/guide", "duplicates 1", "skipped 2", "rejected 1"
    ]

    # strict mode test
    var p2: RuleParser
    p2.open(@["bad!"])
    try:
      discard p2.next()
      doAssert false
    except ValueError:
      discard

    # close test
    p.close()
    doAssert p.accepted.len == 0
    doAssert p.skipped == 0
    doAssert p.rejected == 0
    doAssert p.duplicates == 0
    doAssert p.mode == pmStrict
    doAssert p.label == "default"

  echo "SMOKE: PASS"
