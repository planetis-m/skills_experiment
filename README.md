# Skills Experiment

Empirically verified Nim coding skills, test suites, datasets, and benchmarks.

## Repository Structure

```
prompts/                              # Self-contained prompts for each phase
  phase1_claim_extraction.md          # Extract claims from a skill file
  phase2_empirical_verification.md    # Write and run test programs
  phase3_dataset_curation.md          # Categorize and curate results
  phase4_skill_synthesis.md           # Rewrite skill from verified data
  blind_benchmark.md                  # Double-blind benchmark methodology

skills/
  nim-ownership-hooks/
    SKILL.md                          # AI-verified skill

ai_verified_skills/
  nim-ownership-hooks_VERIFIED.md     # Verified skill (4-section format)

datasets/
  nim-ownership-hooks/
    dataset.json                      # 25 claims, 24 tested, 24 passed

tests/
  nim-ownership-hooks_verification/
    test_c01_auto_managed.nim         # Auto-managed types
    test_c02_hook_lifting.nim         # Hook lifting
    test_c03_raw_pointer.nim          # Raw pointer ownership
    test_c04_export_hooks.nim         # Exported hooks
    test_c05_trace.nim                # =trace under ORC
    test_c06_c07_sentinel.nim         # Sentinel + wasMoved
    test_c08_synthesized_sink.nim     # Synthesized =sink
    test_c09_c10_self_assign.nim      # Self-sink vs self-copy
    test_c11_error_copy.nim           # {.error.} on =copy
    test_c12_dup.nim                  # =dup with nodestroy
    test_c13_lent.nim                 # lent T borrow
    test_c14_sink_affine.nim          # Sink param affinity
    test_c15_sink_duplicate.nim       # Compiler copy for non-last-use
    test_c16_order_bad_generic.nim    # Expected: compile error
    test_c18_template_between.nim     # Templates between type and hooks
    test_c19_move.nim                 # move() semantics
    test_c20_ensuremove.nim           # ensureMove for rvalues
    test_c21_destroy_nonvar.nim       # =destroy(x: T) non-var
    test_c22_sink_shape.nim           # =sink canonical shape
    test_c23_copy_shape.nim           # =copy canonical shape
    test_c24_sink_wasMoved.nim        # wasMoved in sink for partial overwrite
    test_c25_move_optimized.nim       # Move optimization

blind_trials/                         # Double-blind benchmark results
  blind_results.md                    # Full report with unblinding
  {A1,A2,A3,B1,B2,B3}/
    subject_solution.nim              # Generated implementations
    verdict.json                      # Per-trial evaluation

benchmarking_results.md               # Legacy benchmark report
orchestration_system.md               # Subagent orchestration prompt
```

## Running Tests

```bash
cd tests/nim-ownership-hooks_verification

# Run all positive tests
for f in test_c*.nim; do nim r --mm:orc "$f"; done

# Negative test (should fail to compile)
nim c --mm:orc test_c16_order_bad_generic.nim

# Inspect compiler hook insertions
nim c --mm:orc --expandArc:main <test_file>
```

## Running Benchmarks

See `prompts/blind_benchmark.md` for the complete double-blind methodology.

Quick re-run of a single trial:
```bash
cd blind_trials/A1
nim c --mm:orc --path:. -o:test subject_solution.nim
./test
```

Tested with **Nim 2.3.1** and `--mm:orc`.
