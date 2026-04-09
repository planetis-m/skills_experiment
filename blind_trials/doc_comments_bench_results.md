# Benchmark Results: nim-doc-comments

**Date:** 2026-04-09
**Task:** `blind_trials/task_doc_comments.txt`
**Model:** zai/glm-5.1
**Trials per arm:** 3
**Arms:** Original (O), Verified (V), No-skill (N)

## Mapping

| Trial | Arm |
|-------|-----|
| trial_0 | Original |
| trial_1 | Original |
| trial_7 | Original |
| trial_2 | Verified |
| trial_5 | Verified |
| trial_8 | Verified |
| trial_3 | No-skill |
| trial_4 | No-skill |
| trial_6 | No-skill |

## Checklist Scores

| Trial | Arm | Compile+Smoke | nim doc | Phrases (9) | No runnableEx | Private hidden | Overall |
|-------|-----|---------------|---------|-------------|---------------|----------------|---------|
| trial_0 | Original | ✅ | ✅ | 9/9 | ✅ | ✅ | **PASS** |
| trial_1 | Original | ✅ | ✅ | 9/9 | ✅ | ✅ | **PASS** |
| trial_7 | Original | ✅ | ✅ | 9/9 | ✅ | ✅ | **PASS** |
| trial_2 | Verified | ✅ | ✅ | 7/9 | ✅ | ✅ | **PARTIAL** |
| trial_5 | Verified | ✅ | ✅ | 9/9 | ✅ | ✅ | **PASS** |
| trial_8 | Verified | ✅ | ✅ | 9/9 | ✅ | ✅ | **PASS** |
| trial_3 | No-skill | ✅ | ✅ | 9/9 | ✅ | ✅ | **PASS** |
| trial_4 | No-skill | ✅ | ✅ | 9/9 | ✅ | ✅ | **PASS** |
| trial_6 | No-skill | ✅ | ✅ | 9/9 | ✅ | ✅ | **PASS** |

## Per-arm summary

| Arm | Trials | Full PASS | Partial | Fail | Pass rate |
|-----|--------|-----------|---------|------|-----------|
| Original | 3 | 3 | 0 | 0 | 100% |
| Verified | 3 | 2 | 1 | 0 | 67% |
| No-skill | 3 | 3 | 0 | 0 | 100% |

## Mistakes

### trial_2 (Verified skill, arm V)
- **Missing doc on `ParseMode` type declaration**: The agent documented enum values (`pmStrict`, `pmLenient`) but forgot to add a doc comment on the `ParseMode* = enum` line itself. Required phrase "Controls how empty segments are handled" was absent.
- **Missing doc on `ParseConfig` type declaration**: Similarly, the agent documented object fields (`maxDepth`, `allowTabs`) but forgot the doc comment on the `ParseConfig* = object` line. Required phrase "Options that control count parsing" was absent.
- **Root cause**: The verified skill's rules say "attach docs to the declaration line with an inline trailing `##`" but the agent interpreted this as only applying to individual fields/values, not the parent type declaration line itself.

## Interpretation

- **Task is too easy**: 8/9 trials got full PASS. The no-skill arm scored 100%, matching the original arm. The task is well-specified enough that the model doesn't need a skill to complete it.
- **Verified skill did not help**: The verified arm (67%) performed worse than both the original (100%) and no-skill (100%) arms. The single failure in trial_2 was caused by the agent not documenting parent type declarations — arguably the skill's guidance about "declaration-attached docs" wasn't clear enough about type vs field/value distinction.
- **The original skill performed well**: All 3 original-skill trials passed, suggesting the original skill's examples (which show type-level docs like `XmlNodeKind* = enum ## Different kinds of XML nodes.`) may be more helpful than the verified skill's rules.
- **Recommendation**: The task needs to be harder (e.g., require specific `nim doc` output structure, include edge cases in doc placement) to differentiate arms. Alternatively, add a harder sub-task like requiring cross-module doc links or `runnableExamples` that the model would get wrong without guidance.
