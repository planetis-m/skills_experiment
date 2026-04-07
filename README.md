# Skills Experiment

Empirically verified Nim coding skills, test suites, datasets, and benchmarks.

## Repository Structure

```
prompts/                              # Reusable prompt templates
  phase1_claim_extraction.md          # Extract claims from any skill file
  phase2_empirical_verification.md    # Write and run test programs
  phase3_dataset_curation.md          # Categorize and curate results
  phase4_skill_synthesis.md           # Rewrite skill from verified data
  blind_benchmark.md                  # Double-blind benchmark methodology

original_skills/                      # Human-written originals (for benchmarking)
  nim-ownership-hooks/
    SKILL.md                          # Original skill as-is

skills/                              # AI-verified skills (canonical output)
  nim-ownership-hooks/
    SKILL.md                          # Verified skill (4-section format)

datasets/                            # Claim catalogs with test results
  nim-ownership-hooks/
    dataset.json                      # 25 claims, 24 tested, 24 passed

tests/                               # Reproducible test programs
  nim-ownership-hooks_verification/
    test_c01_auto_managed.nim
    test_c02_hook_lifting.nim
    test_c03_raw_pointer.nim
    test_c04_export_hooks.nim
    test_c05_trace.nim
    test_c06_c07_sentinel.nim
    test_c08_synthesized_sink.nim
    test_c09_c10_self_assign.nim
    test_c11_error_copy.nim
    test_c12_dup.nim
    test_c13_lent.nim
    test_c14_sink_affine.nim
    test_c15_sink_duplicate.nim
    test_c16_order_bad_generic.nim
    test_c18_template_between.nim
    test_c19_move.nim
    test_c20_ensuremove.nim
    test_c21_destroy_nonvar.nim
    test_c22_sink_shape.nim
    test_c23_copy_shape.nim
    test_c24_sink_wasMoved.nim
    test_c25_move_optimized.nim

blind_trials/                        # Double-blind benchmark artifacts
  {A1,A2,A3,B1,B2,B3}/
    subject_solution.nim              # Generated implementations
    verdict.json                      # Per-trial evaluation

benchmarking_results.md              # Blind benchmark report with unblinding
```

## Applying the Workflow to a New Skill

1. Copy the original skill to `original_skills/{skill_name}/SKILL.md`
2. Follow `prompts/phase1_claim_extraction.md` → extract claims to `datasets/{skill_name}/dataset.json`
3. Follow `prompts/phase2_empirical_verification.md` → write tests to `tests/{skill_name}_verification/`
4. Follow `prompts/phase3_dataset_curation.md` → curate the dataset
5. Follow `prompts/phase4_skill_synthesis.md` → write verified skill to `skills/{skill_name}/SKILL.md`
6. Follow `prompts/blind_benchmark.md` → compare original vs verified skill

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

Tested with **Nim 2.3.1** and `--mm:orc`.
