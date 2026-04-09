# Prompts

Prompt templates and instruction files for the audit, refinement, and benchmark workflow.

## Start here

Pick the path that matches the job:

1. New skill audit:
   `phase1_claim_extraction.md` -> `phase2_empirical_verification.md` -> `phase3_dataset_curation.md` -> `phase4_skill_synthesis.md`
2. Existing skill refinement:
   read the refinement rules below -> relevant phase prompt(s) -> `benchmark_task_design.md` and `blind_benchmark.md` when benchmark evidence is needed
3. Benchmark design or revision:
   `benchmark_task_design.md`
4. Blind benchmark execution:
   `blind_benchmark.md`

## Refinement rules

Use these rules whenever you improve an existing verified skill:

1. Start from evidence, not intuition.
   Read benchmark verdicts, failed trial outputs, existing tests, dataset notes, and operator notes first.
2. List only concrete failure patterns.
   Each pattern must come from an observed outcome such as a failed test, wrong implementation shape, ambiguous agent behavior, or repeated useless edit.
3. Classify each pattern into one bucket.
   Use only:
   - incorrect claim
   - missing rule
   - ambiguous wording
   - conflicting guidance
   - missing example
   - low-signal noise
4. Choose the smallest edit that addresses the pattern.
   Prefer delete, tighten, or reorder before adding new content.
5. Gate every new line by evidence.
   If a rule, workflow step, example, or mistake entry cannot be tied to an observed pattern, do not add it.
6. Re-run the relevant checks.
   Keep the edit only if it removes the observed failure without introducing new ambiguity.

Hard rules:
- Never overwrite existing tests. Add new tests only.
- Never overwrite the verified skill blindly. Make targeted edits based on new findings.
- Each cycle must expand the dataset, not replace it. Claim IDs only grow.
- Do not add style-only guidance. New skill content must prevent a real observed failure or ambiguity.
- Do not put repo-local process details into the skill. Skills must stay reusable and self-contained.
- Prefer one default pattern per problem shape. Add alternatives only when the evidence shows a real compatibility need.
- Let `Common Mistakes` start empty if needed. Add entries only when recurring failures or ambiguities actually support them.
- Use a `NO SKILL` control arm in benchmarks by default. If it performs as well as the skill-guided runs, revise the task before claiming the skill helped.

## Prompt index

- `phase1_claim_extraction.md`
  Extract distinct claims from a skill into the dataset.
- `phase2_empirical_verification.md`
  Add minimal Nim tests for unverified claims and record outcomes.
- `phase3_dataset_curation.md`
  Normalize verdicts, corrections, and coverage gaps after testing.
- `phase4_skill_synthesis.md`
  Write or refine the verified skill from curated evidence.
- `benchmark_task_design.md`
  Design or revise a benchmark task so it measures real skill value instead of task transcription.
- `blind_benchmark.md`
  Run the blind comparison between skill arms, including the default no-skill control arm.

## Hard rules

- Skills must stay self-contained.
- Prompt files belong under `prompts/`, not at the repo top level.
- Use benchmark outcomes to drive refinement, not to replace tests or the curated dataset.
