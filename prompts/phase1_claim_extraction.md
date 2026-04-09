# Prompt Template: Phase 1 — Claim Extraction

## Purpose
Extract distinct technical claims from a Nim skill file into the dataset.

## Input
- `SKILL_FILE`: path to the skill markdown file to audit

## Instructions

### What counts as a claim

A claim is one distinct statement about Nim behavior or a recommendation with correctness or safety implications.

Include:
- compiler or runtime behavior
- ownership, exception, allocation, or hook semantics
- recommended patterns whose justification depends on correctness

Exclude:
- pure style or readability preferences
- benchmark or audit process notes
- duplicate paraphrases of the same idea
- claims about tools or environments not available in the repo

### Existing dataset handling

If `datasets/{SKILL_NAME}/dataset.json` already exists:
1. Read it first.
2. Preserve all existing top-level fields and all existing claim entries.
3. Append only new claims that are not already represented.
4. Do not renumber, delete, or rewrite existing claims in Phase 1.

If the dataset does not exist, create it with this minimal structure:

```json
{
  "skill_name": "{SKILL_NAME}",
  "source_file": "{SKILL_FILE}",
  "nim_version": "2.3.1",
  "mm_mode": "orc",
  "summary": {},
  "claims": []
}
```

### Refinement gate

If this is a refinement run for an existing verified skill:
1. Read the benchmark verdicts, task notes, and recent failed outcomes first.
2. Extract only claims needed to explain an observed failure, ambiguity, conflict, or coverage gap.
3. Do not append claims for style preferences, speculative agent behavior, or cleanup ideas that are not tied to evidence.

### Extraction procedure

1. Read `{SKILL_FILE}` once from top to bottom.
2. List candidate claims.
3. Merge duplicates so each distinct idea appears once.
4. Compare candidates against the existing dataset, if any.
5. Append only missing claims.
6. Number new claims sequentially after the highest existing `claim_id`.

For each new claim, add:

```json
{
  "claim_id": "C01",
  "claim_text": "exact claim text",
  "is_testable": true,
  "test_file_path": null,
  "test_passed": null,
  "evaluation_notes": null
}
```

Set `is_testable` to `false` only when the claim cannot be checked in this repo without unavailable external systems, libraries, hardware, or environments.

If the dataset already uses additional per-claim fields such as `source` or `compiler_output`, preserve that schema for new entries too.

### Output

Write the updated dataset to `datasets/{SKILL_NAME}/dataset.json`.

Validate the JSON after writing:

```bash
python -m json.tool datasets/{SKILL_NAME}/dataset.json >/dev/null
```

## Reusability
Replace `{SKILL_FILE}` and `{SKILL_NAME}` with the target values.
