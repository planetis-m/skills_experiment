# Prompt Template: Phase 3 — Dataset Curation

## Purpose
Review test results, categorize each claim, and identify corrections needed vs the original skill.

## Inputs
- `DATASET_FILE`: path to `datasets/{SKILL_NAME}/dataset.json` (from Phase 2, with test results)

## Instructions

### Categorize each tested claim

For each claim with `test_passed` set:

| Category | Criteria |
|----------|----------|
| **Deterministic** | Claim is 100% reproducible. Test passes unconditionally. No edge cases found. |
| **Nuanced** | Claim is directionally correct but has exceptions, depends on context, or the test revealed subtleties. Explain in `evaluation_notes`. |
| **Incorrect** | Test disproves the claim. The original skill states something that is factually wrong. |

### Identify corrections

If any claim is **Incorrect** or **Nuanced**, add an entry to the `corrections` array:

```json
{
  "original_claim": "what the skill said",
  "correction": "what the tests actually showed"
}
```

### Validate

- Every `testable` claim must have `test_file_path` and `test_passed` populated
- `summary` totals must be consistent with the claims array
- No empty `evaluation_notes` on failed or nuanced claims

### Output

Write the curated dataset back to the same file: `datasets/{SKILL_NAME}/dataset.json`

## Reusability
Replace `{SKILL_NAME}` and `{DATASET_FILE}` with the target values. No Nim compiler needed — this phase is purely analytical.
