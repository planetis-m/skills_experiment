# Skills Experiment

Empirically verified Nim coding skills, test suites, datasets, and benchmarks.

## Repository Structure

```
orchestration_system.md           # Complete subagent orchestration prompt

skills/
  nim-ownership-hooks/
    SKILL.md                      # AI-verified skill (corrected =destroy signatures)

datasets/
  nim-ownership-hooks/
    dataset.json                  # 32 claims, test outcomes, corrections vs original

tests/
  nim-ownership-hooks_verification/
    test_c01_auto_managed.nim     # Auto-managed types need no hooks
    test_c02_hook_lifting.nim     # Hooks lift through nesting
    test_c03_raw_pointer.nim      # Raw pointers need custom =destroy
    test_c04_export_hooks.nim     # Exported hooks work cross-module
    test_c05_trace.nim            # =trace compiles under ORC
    test_c06_c07_sentinel.nim     # Sentinel check + wasMoved work
    test_c08_synthesized_sink.nim # Compiler-synthesized =sink works
    test_c09_c10_self_assign.nim  # Self-sink eliminated, self-copy needs guard
    test_c11_error_copy.nim       # {.error.} enforces move-only
    test_c12_dup.nim              # =dup with nodestroy works
    test_c13_lent.nim             # lent T provides borrow
    test_c14_sink_affine.nim      # Sink params are affine
    test_c15_sink_duplicate.nim   # Compiler inserts copy for non-last-use
    test_c16_order_good.nim       # Hooks-before-use compiles
    test_c16_order_bad.nim        # Expected: compile error (simple proc)
    test_c16_order_bad_generic.nim# Expected: compile error (generic)
    test_c18_template_between.nim # Templates safe between type and hooks
    test_c19_move.nim             # move() forces move semantics
    test_c20_ensuremove.nim       # ensureMove strict for lvalues
    test_expandArc_verification.nim # Combined expandArc reference test

artifacts/                        # Benchmark artifacts (6 trials)
  original_{1,2,3}/
    subject_solution.nim          # Generated implementation
    stress_test.nim               # 6 edge-case stress tests
    compile.log                   # Compiler output
    run_output.log                # Runtime output
    valgrind.log                  # Valgrind memcheck results
    judge_verdict.json            # 8-criteria evaluation
  verified_{1,2,3}/
    (same structure)

trial_original_skill.md           # Original human-written skill
trial_verified_skill.md           # AI-verified skill (pre-correction)

benchmarking_results.md           # Final comparison report
```

## Running Tests

```bash
# Run claim verification tests
cd tests/nim-ownership-hooks_verification
for f in test_c01*.nim test_c02*.nim test_c03*.nim test_c04*.nim test_c05*.nim \
         test_c06*.nim test_c08*.nim test_c09*.nim test_c11*.nim test_c12*.nim \
         test_c13*.nim test_c14*.nim test_c15*.nim test_c16_order_good.nim \
         test_c18*.nim test_c19*.nim test_c20*.nim test_expandArc*.nim; do
  nim r --mm:orc "$f"
done

# Verify negative cases fail compilation
nim c --mm:orc test_c16_order_bad.nim          # should error
nim c --mm:orc test_c16_order_bad_generic.nim  # should error

# Inspect compiler hook insertions
nim r --mm:orc --expandArc:main test_expandArc_verification.nim
```

## Running Benchmarks

The benchmark pipeline is fully prompt-driven. See `orchestration_system.md` for the complete orchestration prompt that coordinates Generator → Executor → Validator → Judge subagents.

To re-run a single trial's validation:
```bash
cd artifacts/original_1
nim c --mm:orc --path:. -d:useMalloc -o:stress_test_binary stress_test.nim
./stress_test_binary                              # functional tests
valgrind --leak-check=full ./stress_test_binary   # memory safety
```

Tested with **Nim 2.3.1** and `--mm:orc`.
