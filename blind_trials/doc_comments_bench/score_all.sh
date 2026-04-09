#!/usr/bin/env bash
set -euo pipefail

REPODIR="$HOME/skills_experiment"

# Mapping
declare -A ARM
ARM[trial_0]=O
ARM[trial_1]=O
ARM[trial_2]=V
ARM[trial_3]=N
ARM[trial_4]=N
ARM[trial_5]=V
ARM[trial_6]=N
ARM[trial_7]=O
ARM[trial_8]=V

PHRASES=(
  "Parsing helpers for simple comma-separated counts"
  "Default maximum accepted segment count"
  "Controls how empty segments are handled"
  "Rejects empty segments"
  "Skips empty segments"
  "Options that control count parsing"
  "Maximum number of accepted segments"
  "Whether tab characters are treated as whitespace"
  "Parses comma-separated segments and returns their count"
)

for tid in 0 1 2 3 4 5 6 7 8; do
  tdir="$REPODIR/blind_trials/doc_comments_bench/trial_${tid}"
  tname="trial_${tid}"
  arm="${ARM[$tname]}"
  echo ""
  echo "=== $tname (arm=$arm) ==="
  
  nim_file="$tdir/subject_solution.nim"
  if [ ! -f "$nim_file" ]; then
    echo "FAIL: subject_solution.nim missing"
    continue
  fi
  
  # 1. compile+run
  compile_out=$(nim c -r --mm:orc "$nim_file" 2>&1) || true
  smoke_ok=0
  if echo "$compile_out" | grep -q "SMOKE: PASS"; then
    smoke_ok=1
    echo "compile+smoke: PASS"
  else
    echo "compile+smoke: FAIL"
    echo "$compile_out" | tail -5
  fi
  
  # 2. nim doc
  rm -rf "$tdir/htmldocs"
  mkdir -p "$tdir/htmldocs"
  doc_rc=0
  nim doc --outdir:"$tdir/htmldocs" "$nim_file" 2>/dev/null || doc_rc=$?
  doc_ok=0
  if [ "$doc_rc" -eq 0 ]; then
    doc_ok=1
    echo "nim doc: PASS"
  else
    echo "nim doc: FAIL"
  fi
  
  # 3. phrases
  html="$tdir/htmldocs/subject_solution.html"
  phrase_count=0
  if [ "$doc_ok" -eq 1 ] && [ -f "$html" ]; then
    for p in "${PHRASES[@]}"; do
      if grep -q "$p" "$html" 2>/dev/null; then
        phrase_count=$((phrase_count+1))
      else
        echo "  MISSING: $p"
      fi
    done
  fi
  echo "phrases: ${phrase_count}/9"
  
  # 4. no runnableExamples
  has_examples=0
  if grep -q "runnableExamples" "$nim_file" 2>/dev/null; then
    has_examples=1
    echo "runnableExamples: FAIL (present)"
  else
    echo "runnableExamples: OK (absent)"
  fi
  
  # 5. private helper not in docs
  # Get private proc names (no *)
  private_ok=1
  if [ "$doc_ok" -eq 1 ] && [ -f "$html" ]; then
    while IFS= read -r pname; do
      if [ -n "$pname" ]; then
        if grep -q "$pname" "$html" 2>/dev/null; then
          echo "private '$pname' in html: FAIL"
          private_ok=0
        fi
      fi
    done < <(grep -oP 'proc \K[a-zA-Z_][a-zA-Z0-9_]*(?=\([^)]*\)[^{]*$)' "$nim_file" | while read -r name; do
      if ! grep -q "proc ${name}\*(" "$nim_file"; then
        echo "$name"
      fi
    done)
  fi
  if [ "$private_ok" -eq 1 ]; then
    echo "private helper: OK (not in docs)"
  fi
  
  # Summary
  all_ok=0
  if [ "$smoke_ok" -eq 1 ] && [ "$doc_ok" -eq 1 ] && [ "$phrase_count" -eq 9 ] && [ "$has_examples" -eq 0 ] && [ "$private_ok" -eq 1 ]; then
    all_ok=1
    echo "OVERALL: PASS (all checks)"
  else
    echo "OVERALL: PARTIAL"
  fi
done
