# Skills Experiment

Empirically verified Nim coding skills, test suites, datasets, and benchmarks.

## Overview

This repository contains a **self-improving pipeline** for auditing, verifying, and refining Nim coding skills. An OpenClaw agent uses this pipeline to continuously improve skill quality based on empirical evidence.

## Repository Structure

```
prompts/                              # Reusable prompt templates
  phase1_claim_extraction.md          # Extract claims from any skill file
  phase2_empirical_verification.md    # Write and run test programs
  phase3_dataset_curation.md          # Categorize and curate results
  phase4_skill_synthesis.md           # Rewrite skill from verified data
  blind_benchmark.md                  # Double-blind benchmark methodology

original_skills/                      # Human-written originals (read-only)
  nim-ownership-hooks/
    SKILL.md                          # Original skill as-is

skills/                              # AI-verified skills (canonical output)
  nim-ownership-hooks/
    SKILL.md                          # Verified skill (4-section format)

datasets/                            # Claim catalogs with test results
  nim-ownership-hooks/
    dataset.json                      # 25 claims, 24 tested, 24 passed

tests/                               # Reproducible test programs
  nim-ownership-hooks_verification/
    test_c*.nim                       # One file per claim (or claim group)

blind_trials/                        # Double-blind benchmark artifacts
  {A1,A2,A3,B1,B2,B3}/
    subject_solution.nim
    verdict.json

benchmarking_results.md              # Blind benchmark report
```

## How to Use This Repository

### First run (new skill)

To audit a new skill for the first time:

1. Copy the original skill to `original_skills/{skill_name}/SKILL.md`
2. Follow `prompts/phase1_claim_extraction.md` → creates `datasets/{skill_name}/dataset.json`
3. Follow `prompts/phase2_empirical_verification.md` → writes tests to `tests/{skill_name}_verification/`
4. Follow `prompts/phase3_dataset_curation.md` → curates the dataset
5. Follow `prompts/phase4_skill_synthesis.md` → writes `skills/{skill_name}/SKILL.md`
6. (Optional) Follow `prompts/blind_benchmark.md` → compare original vs verified skill

### Refinement run (existing skill)

When the user asks to **improve or refine** a skill that already has verified output:

**Start by reading existing work — do NOT start from scratch.**

1. Read `benchmarking_results.md`. What failed? What was marginal?
2. Read `datasets/{skill_name}/dataset.json`. Check:
   - Are there claims marked **Nuanced** or **Incorrect**?
   - Are there `uncovered_topics` or `needs_stronger_tests` entries from Phase 3?
   - Are there claims with `test_file_path: null` (untested)?
3. Read `skills/{skill_name}/SKILL.md`. Is the verified skill addressing all findings?

**Then enter the refinement loop:**

```
┌──────────────────────────────────────────────┐
│  Refinement Loop                              │
│                                               │
│  Phase 1: Extract NEW claims only             │
│     ↓                                         │
│  Phase 2: Write tests for UNTESTED claims     │
│     ↓                                         │
│  Phase 3: Re-curate ALL claims                │
│     ↓                                         │
│  Phase 4: Targeted edits to verified skill    │
│     ↓                                         │
│  Benchmark: Re-run blind comparison           │
│     ↓                                         │
│  ┌─── Feed failures back to Phase 1 ───┐      │
│  └──────────────────────────────────────┘      │
│                                               │
│  Repeat until no new failures or gaps found    │
└──────────────────────────────────────────────┘
```

**Key rules for refinement:**
- **Never overwrite existing tests.** Add new tests only. Mark old ones as superseded if needed.
- **Never overwrite the verified skill blindly.** Make targeted edits based on new findings.
- **Each cycle must expand the dataset**, not replace it. Claim IDs only grow (C26, C27, ...).
- **Stop when**: the benchmark shows no new failures AND the dataset has no uncovered topics AND all testable claims have passing tests.
- **Commit after each phase** with a descriptive message so progress is tracked.

### What triggers a refinement cycle

- User explicitly asks to improve a skill
- New Nim version changes behavior (re-run tests, check for regressions)
- Benchmark reveals deficiencies in the verified skill
- The dataset has `uncovered_topics` or `needs_stronger_tests` entries

## Prompt Templates

All prompts in `prompts/` are parameterized with these variables:

| Variable | Meaning | Example |
|----------|---------|---------|
| `{SKILL_NAME}` | Skill directory name | `nim-ownership-hooks` |
| `{SKILL_FILE}` | Path to skill to audit | `original_skills/nim-ownership-hooks/SKILL.md` |
| `{DATASET_FILE}` | Path to dataset | `datasets/nim-ownership-hooks/dataset.json` |
| `{ORIGINAL_SKILL}` | Path to original skill | `original_skills/nim-ownership-hooks/SKILL.md` |
| `{VERIFIED_SKILL}` | Path to verified skill | `skills/nim-ownership-hooks/SKILL.md` |
| `{TASK_SPEC}` | Task for benchmark subagents | (provided per benchmark) |
| `{NUM_TRIALS}` | Trials per benchmark group | `3` |

Each prompt includes **existing data handling** instructions so they work for both first-run and refinement scenarios without modification.

## Running Tests

```bash
cd tests/nim-ownership-hooks_verification

# Run all positive tests
for f in test_c*.nim; do nim r --mm:orc --nimcache:../../.nimcache/tests/"${f%.nim}" "$f"; done

# Negative test (should fail to compile)
nim c --mm:orc --nimcache:../../.nimcache/tests/test_c16_order_bad_generic test_c16_order_bad_generic.nim

# Thread-allocation switch test: run once per thread mode
nim r --mm:orc --nimcache:../../.nimcache/tests/test_c39_off test_c39_thread_alloc_switch.nim
nim r --mm:orc --threads:on --nimcache:../../.nimcache/tests/test_c39_on test_c39_thread_alloc_switch.nim

# Inspect compiler hook insertions
nim c --mm:orc --expandArc:main <test_file>
```

Tested with **Nim 2.3.1** and `--mm:orc`.
