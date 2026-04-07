# Prompt Template: Phase 4 — Skill Synthesis

## Purpose
Produce or refine the skill based ONLY on empirically tested data.

## Inputs
- `ORIGINAL_SKILL`: path to `original_skills/{SKILL_NAME}/SKILL.md`
- `DATASET_FILE`: path to `datasets/{SKILL_NAME}/dataset.json` (curated, from Phase 3)
- `CURRENT_VERIFIED_SKILL`: path to `skills/{SKILL_NAME}/SKILL.md` (may not exist yet)

## ⚠️ Critical rule: Self-containment

The skill must be **completely self-contained**. An agent reading only this file — with no access to the dataset, test suite, or audit history — must be able to implement correct ownership hooks.

**Forbidden in the skill:**
- Claim IDs (C01, C02, etc.)
- References to "the dataset" or "the claims"
- Test file names or paths
- Audit process descriptions ("extracted", "tested", "refinement cycle")
- Claim counts or statistics ("35 claims", "31 tested")
- References to benchmark results or trial identifiers

**Required instead:**
- State rules as facts with brief justification ("the compiler eliminates simple self-assignments")
- Code examples that demonstrate the rule directly
- The only permitted metadata is a simple `## Changelog` with dates and brief descriptions of what changed

## Instructions

### Existing skill handling

If `skills/{SKILL_NAME}/SKILL.md` already exists:
1. Read it first. This is the current skill.
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

The file must have exactly these sections, in this order:

#### 1. Preamble
YAML frontmatter with `name` and `description`. Followed by a short human-readable introduction.

#### 2. Verified Stance
Group the verified rules by topic (e.g., "when to write hooks", "hook signatures", "move semantics", "declaration order"). State each rule as a fact with brief justification. Include code examples for each ownership model.

#### 3. Deterministic Workflow
A numbered step-by-step checklist an agent can follow. Each step must be unambiguous:
- Step 1: Classify the ownership model → table of models and their hook sets
- Step 2: Declare hooks before use → ordering rules
- Step 3: Implement the minimal hook set → code examples per model
- Step 4: Verify → `--expandArc` + stress test guidance
- Step 5: Run tests → list of test scenarios

#### 4. Common Mistakes
A table of mistakes and why they are wrong.

### Additional requirements

- Do NOT include the "Empirical Evidence" section with test file tables — that belongs in the dataset, not the skill
- Do NOT include claims that were **Incorrect** — only verified rules
- Mark nuanced rules with their caveats clearly, but as natural prose (not as "Nuanced: ...")
- Code examples must use correct signatures verified by tests
- If the existing skill is already correct for a section, leave it unchanged

### Change log

The skill file must end with a `## Changelog` section:
```markdown
## Changelog
- YYYY-MM-DD: Initial verified version
- YYYY-MM-DD: Added zero-length allocation guidance
```

Keep entries brief. Describe what changed, not the audit process behind it.

### Dataset validation

After updating the skill, validate the dataset:
```bash
python3 -c "import json; json.load(open('datasets/{SKILL_NAME}/dataset.json')); print('Valid')"
```

## Reusability
Replace `{SKILL_NAME}`, `{ORIGINAL_SKILL}`, `{DATASET_FILE}`, and `{CURRENT_VERIFIED_SKILL}` with the target values.
