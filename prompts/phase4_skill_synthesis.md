# Phase 4 Prompt: Workflow Synthesis & Skill Refinement

Based ONLY on the empirically verified data in `nim-ownership-hooks_dataset.json`, write a new skill file.

Save to `ai_verified_skills/nim-ownership-hooks_VERIFIED.md`.

The skill must follow this exact structure:

## 1. Preamble
Name and description in YAML frontmatter.

## 2. Verified Stance
Summary of rules backed by test data. Group by: when to write hooks, hook signatures, move semantics, declaration order.

## 3. Deterministic Workflow
Step-by-step ordered checklist:
1. Classify the ownership model
2. Declare hooks before use
3. Implement minimal hook set per model (with code examples)
4. Verify with --expandArc
5. Run stress tests

## 4. Empirical Evidence
Table referencing test files and their results.

## Constraints
- Do NOT reference the dataset, the audit process, or any meta-information
- The skill must be self-contained — an agent reading only this file can implement correct hooks
- Code examples must use correct signatures (=destroy takes T or var T, no field mutation in destroy)
- Include a "Common mistakes" table
