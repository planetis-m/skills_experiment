# Prompt Template: Phase 4 — Skill Synthesis

## Purpose
Rewrite the original skill into a new, verified skill based ONLY on empirically tested data.

## Inputs
- `ORIGINAL_SKILL`: path to `original_skills/{SKILL_NAME}/SKILL.md`
- `DATASET_FILE`: path to `datasets/{SKILL_NAME}/dataset.json` (curated, from Phase 3)

## Instructions

Read the dataset. Based ONLY on claims where `test_passed` is true, write a new skill file.

### Output path
`skills/{SKILL_NAME}/SKILL.md`

### Required structure

The file must have exactly these four sections, in this order:

#### 1. Preamble
YAML frontmatter with `name` and `description`. Followed by a short human-readable introduction.

#### 2. Verified Stance
Group the verified rules by topic (e.g., "when to write hooks", "hook signatures", "move semantics", "declaration order"). Each rule must be traceable to a test. Include code examples for each ownership model.

#### 3. Deterministic Workflow
A numbered step-by-step checklist an agent can follow. Each step must be unambiguous:
- Step 1: Classify the ownership model → table of models and their hook sets
- Step 2: Declare hooks before use → ordering rules
- Step 3: Implement the minimal hook set → code examples per model
- Step 4: Verify → `--expandArc` + stress test guidance
- Step 5: Run tests → list of test scenarios

#### 4. Empirical Evidence
A table mapping test files to the claims they verify, with pass/fail status.

### Additional requirements

- Include a **Common mistakes** table at the end
- Do NOT reference the dataset, audit process, or any meta-information
- Do NOT include claims that were `Incorrect` — only verified rules
- Mark `Nuanced` claims with their caveats clearly
- Code examples must use correct signatures verified by tests

## Reusability
Replace `{SKILL_NAME}`, `{ORIGINAL_SKILL}`, and `{DATASET_FILE}` with the target values.
