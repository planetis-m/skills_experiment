#!/usr/bin/env bash
set -euo pipefail

WORKDIR="/tmp/nim_doc_comments_test"
REPODIR="$HOME/skills_experiment"
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"

PASS=0
FAIL=0

check() {
  local id="$1" file="$2" pattern="$3"
  if grep -q "$pattern" "$file"; then
    echo "$id: PASS"
    PASS=$((PASS+1))
  else
    echo "$id: FAIL (pattern not found: $pattern)"
    FAIL=$((FAIL+1))
  fi
}

# C01: Module docs at top of file before imports
cat > "$WORKDIR/c01.nim" << 'EOF'
## Module doc for C01.

import std/strutils
proc foo*(): string = "bar"
EOF
nim doc --outdir:"$WORKDIR" "$WORKDIR/c01.nim" 2>/dev/null
check C01 "$WORKDIR/c01.html" 'module-desc.*Module doc for C01'

# C02: Block doc comment ##[ ... ]##
cat > "$WORKDIR/c02.nim" << 'EOF'
##[
Block module doc for C02.
]##

proc bar*(): int = 1
EOF
nim doc --outdir:"$WORKDIR" "$WORKDIR/c02.nim" 2>/dev/null
check C02 "$WORKDIR/c02.html" 'module-desc.*Block module doc for C02'

# C03: Proc doc comments after signature, before body
cat > "$WORKDIR/c03.nim" << 'EOF'
proc greet*(name: string): string =
  ## Greets the person by name.
  result = "hello " & name
EOF
nim doc --outdir:"$WORKDIR" "$WORKDIR/c03.nim" 2>/dev/null
check C03 "$WORKDIR/c03.html" 'Greets the person by name'

# C04: runnableExamples after doc, before body
cat > "$WORKDIR/c04.nim" << 'EOF'
proc double*(x: int): int =
  ## Doubles the value.
  runnableExamples:
    doAssert double(3) == 6
  result = x * 2
EOF
nim doc --outdir:"$WORKDIR" "$WORKDIR/c04.nim" 2>/dev/null
check C04 "$WORKDIR/c04.html" 'Doubles the value'

# C05: Inline trailing ## on type declaration
cat > "$WORKDIR/c05.nim" << 'EOF'
type
  Hash* = int ## A hash value.
EOF
nim doc --outdir:"$WORKDIR" "$WORKDIR/c05.nim" 2>/dev/null
check C05 "$WORKDIR/c05.html" 'A hash value'

# C06: Multi-line ## continuation under declaration
cat > "$WORKDIR/c06.nim" << 'EOF'
type
  Tree* = object ## Mutable builder.
                ## Copying shares the payload.
    p: pointer
EOF
nim doc --outdir:"$WORKDIR" "$WORKDIR/c06.nim" 2>/dev/null
check C06 "$WORKDIR/c06.html" 'Mutable builder'

# C07: nim doc produces HTML with doc content
# Already verified by C01-C06; explicit check that HTML exists
if [ -f "$WORKDIR/c01.html" ]; then
  echo "C07: PASS"
  PASS=$((PASS+1))
else
  echo "C07: FAIL"
  FAIL=$((FAIL+1))
fi

# C08: Exported vs non-exported symbols
cat > "$WORKDIR/c08.nim" << 'EOF'
proc exported*(x: int): int =
  ## This is exported.
  x

proc hidden(x: int): int =
  ## This is not exported.
  x
EOF
nim doc --outdir:"$WORKDIR" "$WORKDIR/c08.nim" 2>/dev/null
if grep -q 'This is exported' "$WORKDIR/c08.html" && ! grep -q 'This is not exported' "$WORKDIR/c08.html"; then
  echo "C08: PASS"
  PASS=$((PASS+1))
else
  echo "C08: FAIL"
  FAIL=$((FAIL+1))
fi

# C09: runnableExamples with failing doAssert causes nim doc to fail
cat > "$WORKDIR/c09.nim" << 'EOF'
proc bad*(x: int): int =
  ## Bad proc.
  runnableExamples:
    doAssert false
  x
EOF
if ! nim doc --outdir:"$WORKDIR" "$WORKDIR/c09.nim" 2>/dev/null; then
  echo "C09: PASS (nim doc failed as expected)"
  PASS=$((PASS+1))
else
  echo "C09: FAIL (nim doc should have failed)"
  FAIL=$((FAIL+1))
fi

# C10: runnableExamples("-d:flag") passes compile flag
cat > "$WORKDIR/c10.nim" << 'EOF'
proc flagged*(): string =
  ## Uses a define.
  runnableExamples("-d:myflag"):
    when defined(myflag):
      doAssert true
    else:
      doAssert false
  result = "ok"
EOF
if nim doc --outdir:"$WORKDIR" "$WORKDIR/c10.nim" 2>/dev/null; then
  echo "C10: PASS"
  PASS=$((PASS+1))
else
  echo "C10: FAIL"
  FAIL=$((FAIL+1))
fi

# C11: Enum value doc on same line
cat > "$WORKDIR/c11.nim" << 'EOF'
type
  Color* = enum ## Colors.
    cRed,    ## The red color.
    cGreen,  ## The green color.
    cBlue    ## The blue color.
EOF
nim doc --outdir:"$WORKDIR" "$WORKDIR/c11.nim" 2>/dev/null
check C11 "$WORKDIR/c11.html" 'The red color'

# C12: Object field docs after field declaration
cat > "$WORKDIR/c12.nim" << 'EOF'
type
  Request* = object ## Parsed request.
    headers*: string ## Request headers.
    port*: int       ## Port number.
EOF
nim doc --outdir:"$WORKDIR" "$WORKDIR/c12.nim" 2>/dev/null
check C12 "$WORKDIR/c12.html" 'Request headers'

# C13: Const doc on same line
cat > "$WORKDIR/c13.nim" << 'EOF'
const
  DefaultPort* = 443 ## Default HTTPS port.
EOF
nim doc --outdir:"$WORKDIR" "$WORKDIR/c13.nim" 2>/dev/null
check C13 "$WORKDIR/c13.html" 'Default HTTPS port'

# C14: Top-level runnableExamples after module docs
cat > "$WORKDIR/c14.nim" << 'EOF'
## Module with top-level example.

runnableExamples:
  doAssert 1 + 1 == 2

proc placeholder*() = discard
EOF
if nim doc --outdir:"$WORKDIR" "$WORKDIR/c14.nim" 2>/dev/null; then
  echo "C14: PASS"
  PASS=$((PASS+1))
else
  echo "C14: FAIL"
  FAIL=$((FAIL+1))
fi

echo ""
echo "Results: $PASS passed, $FAIL failed out of $((PASS+FAIL)) tests"
