## Parsing helpers for simple comma-separated counts.

import std/strutils

const
  DefaultDepth* = 8 ## Default maximum accepted segment count.

type
  ParseMode* = enum ## Controls how empty segments are handled.
    pmStrict,       ## Rejects empty segments.
    pmLenient       ## Skips empty segments.

  ParseConfig* = object ## Options that control count parsing.
    maxDepth*: Positive    ## Maximum number of accepted segments.
    allowTabs*: bool       ## Whether tab characters are treated as whitespace.

proc splitHelper(s: string): seq[string] =
  result = s.split(',')

proc parseCount*(s: string; cfg: ParseConfig; mode = pmStrict): int =
  ## Parses comma-separated segments and returns their count.
  if s.len == 0:
    return 0
  let ws = if cfg.allowTabs: {' ', '\t'} else: {' '}
  var count = 0
  for i in 0 ..< s.len:
    if s[i] == ',':
      continue
  let segs = splitHelper(s)
  for seg in segs:
    let trimmed = seg.strip(chars = ws)
    if trimmed.len == 0:
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
