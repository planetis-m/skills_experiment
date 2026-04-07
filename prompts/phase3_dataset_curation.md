# Phase 3 Prompt: Dataset Curation

Read `nim-ownership-hooks_dataset.json`.

For each claim, categorize as:
- **Deterministic**: Claim is 100% reproducible across runs
- **Nuanced**: Claim is directionally correct but has edge cases or depends on context
- **Incorrect**: Claim is factually wrong based on test results

Identify any corrections needed vs the original skill. Document them in a `corrections` array with:
- `original_claim`: what the skill said
- `correction`: what the tests showed

Output the curated dataset back to `nim-ownership-hooks_dataset.json` with a `summary` object containing totals.
