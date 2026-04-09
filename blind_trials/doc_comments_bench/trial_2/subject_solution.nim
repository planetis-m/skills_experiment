## Parsing helpers for simple comma-separated counts.

import std/strutils

const
  DefaultDepth* = 8 ## Default maximum accepted segment count.

type
  ParseMode* = enum
    pmStrict,   ## Rejects empty segments.
    pmLenient   ## Skips empty segments.

  ParseConfig* = object
    maxDepth*: Positive   ## Maximum number of accepted segments.
    allowTabs*: bool      ## Whether tab characters are treated as whitespace.

proc parseCount*(s: string; cfg: ParseConfig; mode = pmStrict): int =
  ## Parses comma-separated segments and returns their count.
  if s.len == 0:
    return 0
  var count = 0
  for raw in s.split(','):
    var seg = raw.strip()
    if cfg.allowTabs:
      seg = seg.strip(chars = {'\t'})
    if seg.len == 0:
      if mode == pmStrict:
        raise newException(ValueError, "empty segment")
      else:
        continue
    inc count
    if count > cfg.maxDepth:
      raise newException(ValueError, "exceeds maxDepth")
  return count

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
