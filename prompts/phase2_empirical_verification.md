# Prompt Template: Phase 2 — Empirical Verification

## Purpose
Write minimal Nim tests for unverified claims and record the results in the dataset.

## Input
- `DATASET_FILE`: path to `datasets/{SKILL_NAME}/dataset.json`

## Instructions

### Setup

Work from the repo root.

Create these directories if needed:

```bash
mkdir -p tests/{SKILL_NAME}_verification
```

### Existing test handling

If tests already exist in `tests/{SKILL_NAME}_verification/`:
1. Do not overwrite or delete them.
2. Only add new tests for claims where `is_testable` is `true` and `test_file_path` is `null`.
3. If one new test covers multiple untested claims, use one shared file and point every covered claim at that file.

### What to write

For each untested, testable claim:
- Write the smallest test that can prove or disprove it.
- Use a positive runtime test when the claim can be checked by compiling and running code.
- Use a negative compile test only when the claim is specifically about a compile-time restriction or invalid pattern.

File naming:
- Single claim: `test_{claim_id_lowercase}_{short_name}.nim`
- Batched claims: `test_c06_c07_{short_name}.nim`
- Expected compile failure: include `_bad` or `_negative` in the filename

### Test rules

- All tests target `--mm:orc`.
- Positive tests must end with `echo "{CLAIM_ID}: PASS"` or an equivalent combined PASS line for grouped claims.
- Negative tests must fail with a non-zero compiler exit code.
- Do not require manual inspection when an assertion, exit code, or short compiler error check can decide the result.
- Use `--expandArc` only when a normal compile/run test cannot expose the behavior directly.

### Run the new tests

Positive tests:

```bash
for f in tests/{SKILL_NAME}_verification/test_*.nim; do
  case "$f" in
    *_bad*.nim|*_negative*.nim) continue ;;
  esac
  nim r --mm:orc "$f"
done
```

Negative tests:

```bash
for f in tests/{SKILL_NAME}_verification/test_*_bad*.nim tests/{SKILL_NAME}_verification/test_*_negative*.nim; do
  [ -e "$f" ] || continue
  if nim c --mm:orc "$f"; then
    echo "UNEXPECTED PASS: $f"
    exit 1
  fi
done
```

### Update the dataset

For each claim covered by a new test:
- set `test_file_path` to the relative test path
- set `test_passed` to `true` when the observed result matches the claim, otherwise `false`
- set `evaluation_notes` to a short verdict plus any important caveat

If the dataset already uses `compiler_output`, store only the key line or two that explains the result.

Do not modify claims that were already linked to existing tests unless you are adding missing verdict data for that same test.

### Summary handling

Update `summary` so it matches the current claims array.

At minimum keep these counts correct:

```json
{
  "total_claims": 0,
  "testable": 0,
  "passed": 0,
  "failed": 0,
  "not_testable": 0
}
```

If the dataset already tracks extra counts such as `nuanced` or `untested`, recompute those too.

### Validation

Validate the JSON after writing:

```bash
python -m json.tool datasets/{SKILL_NAME}/dataset.json >/dev/null
```

## Reusability
Replace `{SKILL_NAME}` with the target skill name.
