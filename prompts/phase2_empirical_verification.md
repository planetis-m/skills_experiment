# Prompt Template: Phase 2 — Empirical Verification

## Purpose
Write minimal, reproducible test programs that prove or disprove each testable claim from the dataset.

## Inputs
- `DATASET_FILE`: path to `datasets/{SKILL_NAME}/dataset.json` (from Phase 1)

## Instructions

### Setup
Create directory `tests/{SKILL_NAME}_verification/` if it doesn't exist.

### Existing test handling

If tests already exist in `tests/{SKILL_NAME}_verification/`:
1. Do NOT overwrite existing test files. They represent prior verified work.
2. Only write NEW test files for claims that have `test_file_path: null`.
3. If an existing test is known to be wrong, note it in the dataset but do NOT delete it. Add a `superseded_by` field pointing to the new test file.

### For each claim where `is_testable` is true AND `test_file_path` is null

Write a Nim test file named `test_{claim_id_lowercase}_{short_name}.nim`.

**Test program rules:**
- Must compile with `nim c --mm:orc`
- Must print `"{CLAIM_ID}: PASS"` on success
- Use `ptr T` with `alloc`/`dealloc` for raw pointer tests
- Use module-level `var` counters to track hook call counts
- For claims about compiler behavior, use `--expandArc` to inspect hook insertions
- For claims about code quality rules (e.g., "do not X"), write both a correct and incorrect version — the correct one should compile/run, the incorrect one should demonstrate the problem

**Negative tests** (expected compile errors):
- Write the file but do NOT attempt to run it
- Name with `_bad` or `_negative` suffix
- Verify manually that `nim c --mm:orc <file>` produces an error

**Batching:**
- Related claims (e.g., C06 + C07 about sentinel checks) may share a single test file
- Name it `test_c06_c07_{name}.nim`

**Nim 2.3.1 specifics:**
- `ptr T` does not support `[]` indexing. Use `cast[ptr UncheckedArray[T]](ptrVal)[i]` for element access on raw pointers.
- Use `alloc`/`dealloc` (not `alloc0` which may have type issues). Use `copyMem` for bulk copies.
- `create(T)` allocates a single `T`. For arrays, use `alloc(count * sizeof(T))` + cast.
- Import `system` primitives directly; avoid `import std/allocators` (not a standard module).

### Execution

Run all positive tests:
```bash
cd tests/{SKILL_NAME}_verification
for f in test_*.nim; do
  nim r --mm:orc "$f" 2>&1 | grep -E "PASS|FAIL|Error"
done
```

Verify negative tests fail compilation:
```bash
nim c --mm:orc test_*_bad*.nim 2>&1 | grep -i error
```

### Update dataset

For each NEWLY tested claim, update its entry in `datasets/{SKILL_NAME}/dataset.json`:
- `test_file_path`: relative path to the test file
- `test_passed`: `true` if the claim was verified, `false` if disproven
- `compiler_output`: relevant compiler or runtime output (truncated to key lines)
- `evaluation_notes`: verdict, edge cases, any nuance discovered

Do NOT modify entries for claims that already have `test_file_path` set — those are prior verified work.

**Validate the dataset JSON after every update:**
```bash
python3 -c "import json; json.load(open('datasets/{SKILL_NAME}/dataset.json')); print('Valid')"
```
If validation fails, fix the JSON before proceeding.

Fill in the `summary` object:
```json
{
  "total_claims": N,
  "testable": M,
  "passed": P,
  "failed": F,
  "not_testable": U,
  "nuanced": Q
}
```

## Reusability
Replace `{SKILL_NAME}` with the target skill name. Ensure `nim` 2.3.1+ is available with `--mm:orc` support.
