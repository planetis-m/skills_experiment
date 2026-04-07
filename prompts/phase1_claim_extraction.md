# Prompt Template: Phase 1 — Claim Extraction

## Purpose
Extract every falsifiable technical claim from a Nim coding skill document.

## Inputs
- `SKILL_FILE`: path to the skill markdown file to audit

## Instructions

Read `{SKILL_FILE}` in its entirety. Extract every technical claim, assumption, or rule about Nim compiler behavior, hook semantics, or recommended practice.

A **claim** is any statement that can be proven true or false through code execution or compiler behavior. Exclude:
- Purely stylistic preferences without correctness implications
- Meta-commentary about the skill itself
- Claims about external tools not available in the test environment

## Output

Write a JSON file to `datasets/{SKILL_NAME}/dataset.json` with this structure:

```json
{
  "skill_name": "{SKILL_NAME}",
  "source_file": "{SKILL_FILE}",
  "nim_version": "2.3.1",
  "mm_mode": "orc",
  "summary": {},
  "claims": [
    {
      "claim_id": "C01",
      "claim_text": "exact claim text",
      "is_testable": true,
      "test_file_path": null,
      "test_passed": null,
      "compiler_output": null,
      "evaluation_notes": null
    }
  ],
  "corrections": []
}
```

Number claims sequentially: C01, C02, C03, ... Set `is_testable` to `false` only for claims requiring external hardware, C libraries, or runtime environments not available.

## Reusability
This prompt applies to any Nim skill file. Replace `{SKILL_FILE}` and `{SKILL_NAME}` with the target values.
