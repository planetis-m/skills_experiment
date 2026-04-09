# Prompts

Use the smallest prompt that matches the job.

## Choose one

1. New skill audit
   Use in this order:
   `phase1_claim_extraction.md` -> `phase2_empirical_verification.md` -> `phase3_dataset_curation.md` -> `phase4_skill_synthesis.md`

2. Existing benchmark task design or revision
   Use:
   `benchmark_task_design.md`

3. Existing benchmark run
   Use:
   `blind_benchmark.md`

## Prompt index

- `phase1_claim_extraction.md`
  Extract claims from a skill into the dataset.
- `phase2_empirical_verification.md`
  Add minimal tests for unverified claims.
- `phase3_dataset_curation.md`
  Curate verdicts and coverage gaps.
- `phase4_skill_synthesis.md`
  Write or refine the verified skill.
- `benchmark_task_design.md`
  Design or revise a benchmark task.
- `blind_benchmark.md`
  Run an existing benchmark task.

## Hard rules

- `benchmark_task_design.md` is design-only.
- `blind_benchmark.md` is run-only.
- Skills must stay self-contained.
- Prompt files belong under `prompts/`, not at the repo top level.
