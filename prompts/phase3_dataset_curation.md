# Prompt Template: Phase 3 — Dataset Curation

## Purpose
Normalize verdicts, corrections, and coverage notes in the dataset after Phase 2.

## Input
- `DATASET_FILE`: path to `datasets/{SKILL_NAME}/dataset.json`

## Instructions

### Existing curation handling

Always re-read the whole dataset. Do not trust earlier verdict text blindly.

Preserve the existing schema:
- keep current top-level field names
- keep existing claim IDs
- keep any project-specific metadata fields unless they are clearly obsolete

### Review every claim

For each claim:
1. If `is_testable` is `false`, leave `test_file_path` and `test_passed` empty.
2. If `is_testable` is `true` and `test_file_path` is still `null`, record that gap in `needs_stronger_tests`.
3. If `test_passed` is `true`, decide whether the claim is fully deterministic or needs a caveat.
4. If `test_passed` is `false`, treat the claim as incorrect.

Use these categories when writing `evaluation_notes`:

- `DETERMINISTIC.` The claim held as stated.
- `NUANCED.` The claim is useful but needs a caveat or narrower wording.
- `INCORRECT.` The claim was disproven.

Do not add a separate category field unless the dataset already has one.

### Failure-pattern extraction

For refinement runs, also normalize the observed failure patterns before Phase 4.

Use only these buckets:
- incorrect claim
- missing rule
- ambiguous wording
- conflicting guidance
- missing example
- low-signal noise

Only record a pattern when it is supported by an observed benchmark result, failed test, or repeated agent mistake seen in outputs.
Do not invent new patterns from intuition alone.
Store the conclusion in existing fields such as `evaluation_notes`, `corrections`, `uncovered_topics`, or `needs_stronger_tests` instead of adding new schema unless the dataset already supports it.

### Corrections

If a claim is nuanced or incorrect, update the dataset's correction list.

Use the existing correction field name:
- if the dataset already has `corrections_vs_original_skill`, keep using that
- otherwise use `corrections`

Each correction entry should contain:

```json
{
  "original_claim": "what the source skill said",
  "correction": "what the tests actually support"
}
```

Include `claim_id` only if that field already exists in the dataset's correction entries.

### Coverage gaps

Update these arrays:
- `uncovered_topics`: important skill topics not represented by any claim yet
- `needs_stronger_tests`: claims or areas that still need additional tests

Use empty arrays when there are no gaps.

If a claim is semantically verified by normal compile/run tests but still lacks allocator-level or benchmark-level evidence, record that in `needs_stronger_tests` instead of pretending the coverage is complete.

### Summary checks

Make the `summary` counts match the claims array.

At minimum keep these correct:
- `total_claims`
- `testable`
- `passed`
- `failed`
- `not_testable`

If the dataset already tracks `nuanced`, `untested`, or refinement counters, keep those consistent too.

### Validation

Write the curated dataset back to the same file and validate it:

```bash
python -m json.tool datasets/{SKILL_NAME}/dataset.json >/dev/null
```

## Reusability
Replace `{SKILL_NAME}` and `{DATASET_FILE}` with the target values.
