## Parsing helpers for simple comma-separated counts.

const
  DefaultDepth* = 8 ## Default maximum accepted segment count.

type
  ParseMode* = enum
    ## Controls how empty segments are handled.
    pmStrict,   ## Rejects empty segments.
    pmLenient   ## Skips empty segments.

  ParseConfig* = object
    ## Options that control count parsing.
    maxDepth*: Positive   ## Maximum number of accepted segments.
    allowTabs*: bool      ## Whether tab characters are treated as whitespace.

proc splitSegments(s: string; allowTabs: bool): seq[string] =
  ## Private helper: split on commas and trim whitespace.
  result = newSeq[string]()
  var cur = ""
  for ch in s:
    if ch == ',':
      result.add(cur)
      cur = ""
    elif ch == ' ' or (allowTabs and ch == '\t'):
      discard
    else:
      cur.add(ch)
  if s.len > 0:
    result.add(cur)

proc parseCount*(s: string; cfg: ParseConfig; mode = pmStrict): int =
  ## Parses comma-separated segments and returns their count.
  if s.len == 0:
    return 0
  let segs = splitSegments(s, cfg.allowTabs)
  var count = 0
  for seg in segs:
    if seg.len == 0:
      if mode == pmStrict:
        raise newException(ValueError, "empty segment")
      else:
        continue
    inc count
    if count > cfg.maxDepth:
      raise newException(ValueError, "exceeds maxDepth")
  result = count

when isMainModule:
  let cfg = ParseConfig(maxDepth: 3, allowTabs: true)
  assert parseCount("", cfg) == 0
  assert parseCount("a,b,c", cfg) == 3
  assert parseCount("a, b ,c", cfg) == 3
  assert parseCount("a,,c", cfg, pmLenient) == 2
  try:
    discard parseCount("a,,c", cfg, pmStrict)
    assert false
  except ValueError:
    discard
  try:
    discard parseCount("a,b,c,d", cfg, pmLenient)
    assert false
  except ValueError:
    discard
  echo "SMOKE: PASS"
