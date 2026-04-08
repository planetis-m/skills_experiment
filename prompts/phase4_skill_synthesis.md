# Prompt Template: Phase 4 — Skill Synthesis

## Purpose
Produce or refine the skill based ONLY on empirically tested data.

## Inputs
- `ORIGINAL_SKILL`: path to `original_skills/{SKILL_NAME}/SKILL.md`
- `DATASET_FILE`: path to `datasets/{SKILL_NAME}/dataset.json` (curated, from Phase 3)
- `CURRENT_VERIFIED_SKILL`: path to `skills/{SKILL_NAME}/SKILL.md` (may not exist yet)

## ⚠️ Critical rules

### Rule 1: Self-containment

The skill must be **completely self-contained**. An agent reading only the skill files — with no access to the dataset, test suite, or audit history — must be able to implement correct code.

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

### Rule 2: Workflow focus with external examples

The main `SKILL.md` must be **focused on the deterministic workflow** — rules, decision tables, and step-by-step procedures. It should be concise and scannable.

**Code examples belong in `references/`:**
- Create `skills/{SKILL_NAME}/references/` directory
- Each ownership model or common pattern gets its own file (e.g., `references/move_only_owner.md`, `references/shared_refcounted.md`)
- The main `SKILL.md` may include **at most one inline example** — the single most common pattern for that skill
- All other examples go into `references/` and are linked from the main file via a `## References` section

**Which examples to include:**
- Include examples that demonstrate **common, widely-applicable patterns** — patterns a developer would encounter in real code
- Do NOT add examples just because they appeared in benchmarks or tests
- Do NOT add examples for edge cases or rare patterns — those belong as rules or common-mistakes entries
- A good heuristic: if the pattern appears in a standard library, it's common enough for a reference file

**Example structure for `references/`:**
```
skills/{SKILL_NAME}/
  SKILL.md                        # Rules + workflow + one inline example
  references/
    common_pattern_a.md           # Full working code with brief explanation
    common_pattern_b.md           # Full working code with brief explanation
    ...
```

## Instructions

### Existing skill handling

If `skills/{SKILL_NAME}/SKILL.md` already exists:
1. Read it first. Read any existing `references/` files too.
2. Read the curated dataset. Compare the dataset state against the skill.
3. Reason about what needs improvement:
   - Are there newly tested claims not reflected in the skill?
   - Were any claims marked **Nuanced** or **Incorrect** in this iteration?
   - Do the code examples still match verified behavior?
   - Are there coverage gaps identified in Phase 3?
4. **Do NOT overwrite the skill blindly.** Make targeted edits to reflect new findings.
5. Preserve sections that are still verified correct. Only update what changed.
6. If adding a new code example, decide: is it common enough for `references/`, or does it belong as a rule/common-mistake entry?

If `skills/{SKILL_NAME}/SKILL.md` does NOT exist, create it from scratch following the structure below.

### Output paths
- Main skill: `skills/{SKILL_NAME}/SKILL.md`
- Reference examples: `skills/{SKILL_NAME}/references/*.md`

### Required structure for SKILL.md

The file must have exactly these sections, in this order:

#### 1. Preamble
YAML frontmatter with `name` and `description`. Followed by a short human-readable introduction that mentions the `references/` directory.

#### 2. Rules
Group the verified rules by topic. State each rule as a fact with brief justification. Keep this section concise — no full code examples here (link to references instead).

#### 3. Workflow
A numbered step-by-step checklist an agent can follow. Each step must be unambiguous:
- Step 1: Classify the problem → decision table
- Step 2: Setup → ordering, declarations
- Step 3: Implement → link to the appropriate `references/` file for each variant
- Step 4: Verify → how to check correctness
- Step 5: Test → what to test

At most one inline code example — for the most common pattern only.

#### 4. Common Mistakes
A table of mistakes and why they are wrong.

#### 5. References
A list linking to each `references/` file with a one-line description.

#### 6. Changelog
```markdown
## Changelog
- YYYY-MM-DD: Initial version
- YYYY-MM-DD: Added X guidance
```

### Required structure for reference files

Each file in `references/` must:
- Have a descriptive filename (e.g., `move_only_owner.md`, not `example1.md`)
- Start with a one-line description of the pattern
- Contain a **complete, compilable** code example
- End with a brief "Key points" or "When to use" section
- Be self-contained — an agent can copy-paste and adapt

### Additional requirements

- Do NOT include the "Empirical Evidence" section with test file tables — that belongs in the dataset, not the skill
- Do NOT include claims that were **Incorrect** — only verified rules
- Mark nuanced rules with their caveats clearly, but as natural prose (not as "Nuanced: ...")
- Code examples must use correct signatures verified by tests
- If the existing skill is already correct for a section, leave it unchanged

### Dataset validation

After updating the skill, validate the dataset:
```bash
python3 -c "import json; json.load(open('datasets/{SKILL_NAME}/dataset.json')); print('Valid')"
```

## Reusability
Replace `{SKILL_NAME}`, `{ORIGINAL_SKILL}`, `{DATASET_FILE}`, and `{CURRENT_VERIFIED_SKILL}` with the target values.
