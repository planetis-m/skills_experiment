#!/bin/bash
set -e

TASK='Create a Nim source file called subject_solution.nim implementing a custom String type with Reference Counting and Copy-on-Write (CoW) semantics using raw pointers (ptr) and manual memory management.

Required type and exports (a validator depends on these exact signatures):

type
  StrPayload* = object
    cap*, counter*: int
    data*: UncheckedArray[char]
  String* = object
    len*: int
    p*: ptr StrPayload

proc initString*(s: var String; data: string)
proc getStr*(s: String): string
proc mutateAt*(s: var String; i: int; c: char)  # must trigger CoW when refcount > 1
proc `=destroy`*(x: String)
proc `=wasMoved`*(x: var String)
proc `=dup`*(b: String): String
proc `=copy`*(a: var String; b: String)

The file must compile with nim c --mm:orc and be importable as a module. Export all procs and types. Use dealloc/deallocShared for cleanup depending on threads option. Only write subject_solution.nim — no other files.'

BASE="/tmp/skills_experiment"
RESULTS="$BASE/benchmark_results.txt"
> "$RESULTS"

run_trial() {
  local label="$1"
  local trial_num="$2"
  local skill_file="$3"
  
  local DIR="$BASE/trials/${label}_${trial_num}"
  rm -rf "$DIR" && mkdir -p "$DIR"
  
  # Inject skill as AGENTS.md
  cp "$skill_file" "$DIR/AGENTS.md"
  
  echo "" | tee -a "$RESULTS"
  echo "========== $label TRIAL $trial_num ==========" | tee -a "$RESULTS"
  
  # Run crush
  cd "$DIR"
  crush run -c "$DIR" "$TASK" 2>&1 | tail -3
  
  # Check output
  if [ -f "$DIR/subject_solution.nim" ]; then
    echo "[OK] subject_solution.nim created ($(wc -l < "$DIR/subject_solution.nim") lines)" | tee -a "$RESULTS"
    
    # Try to compile with validator
    cp "$BASE/validator.nim" "$DIR/validator.nim"
    COMPILE_OUT=$(nim c --mm:orc --path:"$DIR" -o:"$DIR/validator_bin" "$DIR/validator.nim" 2>&1)
    if [ $? -eq 0 ]; then
      echo "[COMPILE OK]" | tee -a "$RESULTS"
      # Run it
      RUN_OUT=$("$DIR/validator_bin" 2>&1)
      if [ $? -eq 0 ]; then
        echo "[RUN PASS]" | tee -a "$RESULTS"
        echo "$RUN_OUT" >> "$RESULTS"
      else
        echo "[RUN FAIL]" | tee -a "$RESULTS"
        echo "$RUN_OUT" | tail -20 >> "$RESULTS"
      fi
    else
      echo "[COMPILE FAIL]" | tee -a "$RESULTS"
      echo "$COMPILE_OUT" | grep -i "error" | head -5 >> "$RESULTS"
    fi
  else
    echo "[FAIL] subject_solution.nim NOT created" | tee -a "$RESULTS"
    ls "$DIR"/*.nim 2>/dev/null >> "$RESULTS" || echo "  No .nim files found" >> "$RESULTS"
  fi
}

ORIGINAL="$BASE/trial_original_skill.md"
VERIFIED="$BASE/trial_verified_skill.md"

echo "Starting 6 trials..." | tee -a "$RESULTS"

for i in 1 2 3; do
  run_trial "original" "$i" "$ORIGINAL"
  echo "Waiting 30s to avoid rate limit..."
  sleep 30
done

for i in 1 2 3; do
  run_trial "verified" "$i" "$VERIFIED"
  echo "Waiting 30s to avoid rate limit..."
  sleep 30
done

echo "" | tee -a "$RESULTS"
echo "========== ALL TRIALS COMPLETE ==========" | tee -a "$RESULTS"
