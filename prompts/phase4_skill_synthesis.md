# Prompt Template: Phase 4 — Skill Synthesis

## Purpose
Create or refine the verified skill from the curated dataset.

## Inputs
- `ORIGINAL_SKILL`: path to `original_skills/{SKILL_NAME}/SKILL.md`
- `DATASET_FILE`: path to `datasets/{SKILL_NAME}/dataset.json`
- `CURRENT_VERIFIED_SKILL`: path to `skills/{SKILL_NAME}/SKILL.md` (may not exist)

## Rules

### Source of truth

Use the curated dataset as the source of truth.

Include:
- claims supported by tests
- caveats supported by `evaluation_notes`

Exclude:
- disproven claims
- audit-process details
- claim IDs, test names, benchmark trial names, and claim counts

### Evidence-gated refinement

When refining an existing skill:
1. Start from observed failures and ambiguities, not from general cleanup ideas.
2. Map each proposed edit to one concrete pattern:
   incorrect claim, missing rule, ambiguous wording, conflicting guidance, missing example, or low-signal noise.
3. Prefer delete, tighten, or reorder before adding new text.
4. Do not add a new rule, workflow step, or mistake entry unless the dataset or benchmark evidence supports it.
5. Do not add repo-local process details to the skill.
6. Do not add style-only guidance unless it prevents a real observed failure.

### Keep the skill self-contained

An agent reading only the skill files must be able to act on them without opening the dataset.

The skill may contain:
- rules stated as facts
- decision tables
- short workflows
- code examples
- a short changelog

The skill must not contain:
- references to phases or refinement cycles
- references to dataset internals
- references to benchmark scores

### Existing skill handling

If `CURRENT_VERIFIED_SKILL` exists:
1. Read the current verified skill and its `references/` files first.
2. Read the curated dataset.
3. Make targeted edits instead of rewriting everything.
4. Keep sections and examples that are still correct.

If `CURRENT_VERIFIED_SKILL` does not exist, create it from scratch.

## Required output structure

`skills/{SKILL_NAME}/SKILL.md` must contain these sections in this order:

1. `Preamble`
2. `Rules`
3. `Workflow`
4. `Common Mistakes`
5. `References`
6. `Changelog`

### Section guidance

#### Preamble
- YAML frontmatter with `name` and `description`
- a short introduction
- one sentence telling the reader where `references/` examples live

#### Rules
- short, high-signal rules grouped by topic
- no long code samples

#### Workflow
- a short numbered procedure
- each step should tell the agent what to decide or do next
- keep it self-contained and reusable
- if verification is mentioned, refer only to the target project's own tests or checks

#### Common Mistakes
- short table: mistake and why it is wrong
- include only mistakes supported by the curated data or repeated benchmark failures
- do not invent hypothetical anti-patterns just to make the table longer
- if there are no supported recurring mistakes yet, keep the section minimal instead of filling it with guesses
- a short line such as `No recurring mistakes recorded yet.` is acceptable until evidence exists

#### References
- list each reference file with a one-line description

#### Changelog
- one flat bullet list with dates and short descriptions

## Reference files

Store larger examples in `skills/{SKILL_NAME}/references/`.

Each reference file must:
- use a descriptive filename
- begin with a one-line description
- contain one complete example
- end with a short `Key points` or `When to use` section

## Example policy

- Keep the main `SKILL.md` concise.
- Use at most one inline example in the main file.
- Put the rest in `references/`.
- Prefer one default pattern per problem shape.
- If an alternative exists only for compatibility with an established codebase, label it explicitly as a compatibility note instead of presenting it as an equal default.

## Output paths

- Main skill: `skills/{SKILL_NAME}/SKILL.md`
- Reference examples: `skills/{SKILL_NAME}/references/*.md`

## Reusability
Replace `{SKILL_NAME}`, `{ORIGINAL_SKILL}`, `{DATASET_FILE}`, and `{CURRENT_VERIFIED_SKILL}` with the target values.
