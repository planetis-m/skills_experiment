## Parsing helpers for simple comma-separated counts.

import std/strutils

const
  DefaultDepth* = 8 ## Default maximum accepted segment count.

type
  ParseMode* = enum ## Controls how empty segments are handled.
    pmStrict,       ## Rejects empty segments.
    pmLenient       ## Skips empty segments.

  ParseConfig* = object ## Options that control count parsing.
    maxDepth*: Positive ## Maximum number of accepted segments.
    allowTabs*: bool    ## Whether tab characters are treated as whitespace.

proc trimSegment(s: string): string =
  var ws = {' ', '\t'}
  s.strip(chars = ws)

proc parseCount*(s: string; cfg: ParseConfig; mode = pmStrict): int =
  ## Parses comma-separated segments and returns their count.
  if s.len == 0:
    return 0
  let parts = s.split(',')
  var count = 0
  for seg in parts:
    let trimmed = seg.strip()
    if trimmed.len == 0:
      if mode == pmStrict:
        raise newException(ValueError, "empty segment")
      else:
        continue
    count.inc
    if count > cfg.maxDepth:
      raise newException(ValueError, "too many segments")
  result = count

when isMainModule:
  let cfg = ParseConfig(maxDepth: 3, allowTabs: true)
  doAssert parseCount("", cfg) == 0
  doAssert parseCount("a,b,c", cfg) == 3
  doAssert parseCount("a, b ,c", cfg) == 3
  doAssert parseCount("a,,c", cfg, pmLenient) == 2
  try:
    discard parseCount("a,,c", cfg, pmStrict)
    doAssert false
  except ValueError:
    discard
  try:
    discard parseCount("a,b,c,d", cfg, pmLenient)
    doAssert false
  except ValueError:
    discard
  echo "SMOKE: PASS"
