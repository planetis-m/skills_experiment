# Prompt Template: Phase 3 — Dataset Curation

## Purpose
Review test results, categorize each claim, and identify corrections needed vs the original skill.

## Inputs
- `DATASET_FILE`: path to `datasets/{SKILL_NAME}/dataset.json` (from Phase 2, with test results)

## Instructions

### Existing curation handling

If the dataset already has `evaluation_notes` filled in for some claims:
1. Re-evaluate ALL claims, including previously curated ones.
2. New tests or new claims may change the verdict of existing claims.
3. Do NOT assume prior curation is still correct — verify against the current test suite.
4. If a previously-passing claim now fails (e.g., due to Nim version change), update it.

### Categorize each tested claim

For each claim with `test_passed` set:

| Category | Criteria |
|----------|----------|
| **Deterministic** | Claim is 100% reproducible. Test passes unconditionally. No edge cases found. |
| **Nuanced** | Claim is directionally correct but has exceptions, depends on context, or the test revealed subtleties. Explain in `evaluation_notes`. |
| **Incorrect** | Test disproves the claim. The original skill states something that is factually wrong. |

### Identify corrections

If any claim is **Incorrect** or **Nuanced**, add or update entries in the `corrections` array:

```json
{
  "claim_id": "C01",
  "original_claim": "what the skill said",
  "correction": "what the tests actually showed"
}
```

### Identify coverage gaps

After curation, check:
1. Are there aspects of the skill NOT covered by any claim? List them as `uncovered_topics`.
2. Are there claims that could benefit from additional negative tests? List them as `needs_stronger_tests`.

These gaps feed back into Phase 1 for the next iteration.

### Validate

- Every `testable` claim must have `test_file_path` and `test_passed` populated
- `summary` totals must be consistent with the claims array
- No empty `evaluation_notes` on failed or nuanced claims

### Output

Write the curated dataset back to the same file: `datasets/{SKILL_NAME}/dataset.json`

**Validate the dataset JSON after writing:**
```bash
python3 -c "import json; json.load(open('datasets/{SKILL_NAME}/dataset.json')); print('Valid')"
```

## Reusability
Replace `{SKILL_NAME}` and `{DATASET_FILE}` with the target values. No Nim compiler needed — this phase is purely analytical.
