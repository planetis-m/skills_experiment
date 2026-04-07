# Prompt Template: Phase 4 — Skill Synthesis

## Purpose
Produce or refine a verified skill based ONLY on empirically tested data.

## Inputs
- `ORIGINAL_SKILL`: path to `original_skills/{SKILL_NAME}/SKILL.md`
- `DATASET_FILE`: path to `datasets/{SKILL_NAME}/dataset.json` (curated, from Phase 3)
- `CURRENT_VERIFIED_SKILL`: path to `skills/{SKILL_NAME}/SKILL.md` (may not exist yet)

## Instructions

### Existing skill handling

If `skills/{SKILL_NAME}/SKILL.md` already exists:
1. Read it first. This is the current verified skill.
2. Read the curated dataset. Compare the dataset state against the skill.
3. Reason about what needs improvement:
   - Are there newly tested claims not reflected in the skill?
   - Were any claims marked **Nuanced** or **Incorrect** in this iteration?
   - Do the code examples still match verified behavior?
   - Are there coverage gaps identified in Phase 3?
4. **Do NOT overwrite the skill blindly.** Make targeted edits to reflect new findings.
5. Preserve sections that are still verified correct. Only update what changed.

If `skills/{SKILL_NAME}/SKILL.md` does NOT exist, create it from scratch following the structure below.

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
- Do NOT include claims that were **Incorrect** — only verified rules
- Mark **Nuanced** claims with their caveats clearly
- Code examples must use correct signatures verified by tests
- If the existing skill is already correct for a section, leave it unchanged

### Change log

At the end of the skill file, maintain a changelog:
```markdown
## Changelog
- YYYY-MM-DD: Initial verified version
- YYYY-MM-DD: Added C26-C30 coverage. Updated code examples for shared handle model.
```

## Reusability
Replace `{SKILL_NAME}`, `{ORIGINAL_SKILL}`, `{DATASET_FILE}`, and `{CURRENT_VERIFIED_SKILL}` with the target values.
