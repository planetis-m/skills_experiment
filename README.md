# Skills Experiment

Empirically verified Nim coding skills, test suites, and datasets.

## Repository structure

```
skills/                          # Verified skill documents
  nim-ownership-hooks/
    SKILL.md                     # Ownership hooks & move semantics skill

datasets/                        # Structured claim catalogs with test results
  nim-ownership-hooks/
    dataset.json                 # 32 claims, test outcomes, corrections

tests/                           # Reproducible Nim test programs
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
    test_c16_order_good.nim
    test_c16_order_bad.nim       # Expected: compile error
    test_c16_order_bad_generic.nim # Expected: compile error (generic case)
    test_c18_template_between.nim
    test_c19_move.nim
    test_c20_ensuremove.nim
    test_expandArc_verification.nim  # Combined expandArc reference test
```

## Running the tests

```bash
# Run all passing tests
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

Tested with **Nim 2.3.1** using `--mm:orc`.

## Dataset format

Each dataset JSON contains:

| Field | Description |
|-------|-------------|
| `claim_id` | Unique identifier |
| `claim_text` | The original claim |
| `source` | Where the claim originated |
| `is_testable` | Whether it can be programmatically verified |
| `test_file_path` | Path to the test file (if testable) |
| `test_passed` | Whether the test confirmed the claim |
| `compiler_output` | Relevant compiler/run output |
| `expandArc_evidence` | Hook insertion evidence from `--expandArc` (where applicable) |
| `evaluation_notes` | Verdict and nuance |
