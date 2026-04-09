#!/usr/bin/env bash
set -euo pipefail

WORKDIR="/tmp/nim_code_org_test"
REPODIR="$HOME/skills_experiment"
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"

PASS=0
FAIL=0

# C05: Nested proc capturing mutable outer var compiles under ORC
cat > "$WORKDIR/c05.nim" << 'EOF'
proc run() =
  let total = 10
  var nextToWrite = 0
  proc flushReady() =
    if nextToWrite < total:
      inc nextToWrite
  flushReady()
  doAssert nextToWrite == 1
run()
echo "C05: PASS"
EOF
if nim c -r --mm:orc "$WORKDIR/c05.nim" 2>&1; then
  PASS=$((PASS+1))
  echo "C05: PASS"
else
  FAIL=$((FAIL+1))
  echo "C05: FAIL"
fi

# C06: Explicit state object with var parameter modifies correctly
cat > "$WORKDIR/c06.nim" << 'EOF'
type
  WriteState = object
    nextToWrite: int

proc flushReady(state: var WriteState; total: int) =
  if state.nextToWrite < total:
    inc state.nextToWrite

var s = WriteState(nextToWrite: 0)
flushReady(s, 10)
doAssert s.nextToWrite == 1
echo "C06: PASS"
EOF
if nim c -r --mm:orc "$WORKDIR/c06.nim" 2>&1; then
  PASS=$((PASS+1))
  echo "C06: PASS"
else
  FAIL=$((FAIL+1))
  echo "C06: FAIL"
fi

# C01: Nested proc capturing mutable outer var — verify behavior is actually correct (no ORC corruption)
# This tests that the nested closure pattern does produce correct results for simple cases
cat > "$WORKDIR/c01.nim" << 'EOF'
proc run() =
  var counter = 0
  proc incCounter() =
    inc counter
  for i in 0..<100:
    incCounter()
  doAssert counter == 100
run()
echo "C01: PASS"
EOF
if nim c -r --mm:orc "$WORKDIR/c01.nim" 2>&1; then
  PASS=$((PASS+1))
  echo "C01: PASS (nested closure works correctly in simple case)"
else
  FAIL=$((FAIL+1))
  echo "C01: FAIL"
fi

# C03: Unused import produces warning
cat > "$WORKDIR/c03.nim" << 'EOF'
import std/strutils
proc foo*(): int = 42
EOF
OUTPUT=$(nim c --mm:orc "$WORKDIR/c03.nim" 2>&1)
if echo "$OUTPUT" | grep -qi "UnusedImport\|imported and not used"; then
  PASS=$((PASS+1))
  echo "C03: PASS (UnusedImport warning present)"
else
  FAIL=$((FAIL+1))
  echo "C03: FAIL (no UnusedImport warning found)"
  echo "$OUTPUT"
fi

# C04: Non-exported symbol inaccessible from other module
mkdir -p "$WORKDIR/mod"
cat > "$WORKDIR/mod/hidden.nim" << 'EOF'
proc internalProc(): int = 42
proc exportedProc*(): int = 99
EOF
cat > "$WORKDIR/c04.nim" << 'EOF'
import mod/hidden
echo exportedProc()
EOF
# Should compile fine using exported proc
if nim c -r --mm:orc --path:"$WORKDIR" "$WORKDIR/c04.nim" 2>&1; then
  PASS=$((PASS+1))
  echo "C04a: PASS (exported symbol accessible)"
else
  FAIL=$((FAIL+1))
  echo "C04a: FAIL"
fi

# Try to use non-exported — should fail
cat > "$WORKDIR/c04b.nim" << 'EOF'
import mod/hidden
echo internalProc()
EOF
if ! nim c --mm:orc --path:"$WORKDIR" "$WORKDIR/c04b.nim" 2>/dev/null; then
  PASS=$((PASS+1))
  echo "C04b: PASS (non-exported symbol inaccessible)"
else
  FAIL=$((FAIL+1))
  echo "C04b: FAIL (non-exported symbol should not be accessible)"
fi

# C02: State object pattern avoids closure entirely (no closure env allocation)
cat > "$WORKDIR/c02.nim" << 'EOF'
type
  PipelineState = object
    step: int
    data: string

proc runStep(s: var PipelineState; payload: string) =
  inc s.step
  s.data = payload

var state = PipelineState(step: 0, data: "")
runStep(state, "hello")
runStep(state, "world")
doAssert state.step == 2
doAssert state.data == "world"
echo "C02: PASS"
EOF
if nim c -r --mm:orc "$WORKDIR/c02.nim" 2>&1; then
  PASS=$((PASS+1))
  echo "C02: PASS"
else
  FAIL=$((FAIL+1))
  echo "C02: FAIL"
fi

echo ""
echo "Results: $PASS passed, $FAIL failed out of $((PASS+FAIL)) tests"
