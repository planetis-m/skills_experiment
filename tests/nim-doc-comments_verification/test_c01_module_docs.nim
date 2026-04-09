## Utilities for parsing configuration values.
##
## This module demonstrates module-level docs.

proc sample*(): int = 42

when isMainModule:
  # Verify: the source file itself starts with ## before any code.
  # We just need compilation + nim doc to succeed; the HTML check is external.
  echo "C01: PASS"
