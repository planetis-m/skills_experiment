# Skills Experiment

Empirically verified Nim coding skills, test suites, datasets, and benchmarks.

## Overview

This repository contains a small pipeline for auditing, verifying, and refining Nim coding skills with datasets, tests, and benchmark tasks.

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
    SKILL.md                          # Verified skill

datasets/                            # Claim catalogs with test results
  nim-ownership-hooks/
    dataset.json                      # Curated claims and verdicts

tests/                               # Reproducible test programs
  nim-ownership-hooks_verification/
    test_c*.nim                       # One file per claim (or claim group)

blind_trials/                        # Double-blind benchmark artifacts
  task*.txt                          # Canonical task specs
  stress_test*.nim                   # Optional benchmark-only helper programs
  # per-run workspaces and verdicts are temporary and should not be committed
```

## How to Use This Repository

### First run (new skill)

To audit a new skill for the first time:

1. Copy the original skill to `original_skills/{skill_name}/SKILL.md`
2. Follow `prompts/phase1_claim_extraction.md` → creates `datasets/{skill_name}/dataset.json`
3. Follow `prompts/phase2_empirical_verification.md` → writes tests to `tests/{skill_name}_verification/`
4. Follow `prompts/phase3_dataset_curation.md` → curates the dataset
5. Follow `prompts/phase4_skill_synthesis.md` → writes `skills/{skill_name}/SKILL.md`
6. (Optional) Follow `prompts/benchmark_task_design.md` → design or refine one benchmark task
7. (Optional) Follow `prompts/blind_benchmark.md` → compare original vs verified skill

### Refinement run (existing skill)

When the user asks to **improve or refine** a skill that already has verified output:

**Start by reading existing work — do NOT start from scratch.**

1. Read the most relevant benchmark task for that skill, plus any local operator notes if they exist. Identify concrete failures, ambiguity, or ceiling effects.
2. Read `datasets/{skill_name}/dataset.json`. Check:
   - Are there corrections or caveats already recorded?
   - Are there `uncovered_topics` or `needs_stronger_tests` entries from Phase 3?
   - Are there claims with `test_file_path: null` (untested)?
3. Read `skills/{skill_name}/SKILL.md`. Is the verified skill addressing all findings?

Then run the refinement loop:
1. Phase 1: Extract only new claims
2. Phase 2: Add tests only for untested or under-tested claims
3. Phase 3: Re-curate the whole dataset
4. Phase 4: Make targeted edits to the verified skill
5. Revisit `prompts/benchmark_task_design.md` if the benchmark may be too tight, too easy, or too weakly scored
6. Re-run the relevant benchmark or task comparison
7. Feed any new failures back into Phase 1

### Principled refinement procedure

Use this procedure whenever you improve an existing skill.

1. Start from evidence, not intuition.
   Read benchmark verdicts, failed trial outputs, existing tests, and operator notes first.
2. List only concrete failure patterns.
   Each pattern must come from an observed outcome such as a failed test, a wrong implementation shape, ambiguous agent behavior, or a repeated useless edit.
3. Classify each pattern into one bucket.
   Use only: incorrect claim, missing rule, ambiguous wording, conflicting guidance, missing example, or low-signal noise.
4. Choose the smallest edit that addresses the pattern.
   Prefer delete, tighten, or reorder before adding new content.
5. Gate every new line by evidence.
   If a rule, workflow step, or mistake entry cannot be tied to an observed pattern, do not add it.
6. Re-run the relevant checks.
   Keep the edit only if it removes the observed failure without introducing new ambiguity.

**Key rules for refinement:**
- **Never overwrite existing tests.** Add new tests only. Mark old ones as superseded if needed.
- **Never overwrite the verified skill blindly.** Make targeted edits based on new findings.
- **Each cycle must expand the dataset**, not replace it. Claim IDs only grow (C26, C27, ...).
- **Do not add style-only guidance.** New skill content must prevent a real observed failure or ambiguity.
- **Do not put repo-local process details into the skill.** Skills must stay reusable and self-contained.
- **Prefer one default pattern per problem shape.** Add alternatives only when the evidence shows a real compatibility need.
- **Let `Common Mistakes` start empty if needed.** Add entries only when recurring failures or ambiguities actually support them.
- **Use a `NO SKILL` control arm in benchmarks by default.** If it performs as well as the skill-guided runs, revise the task before claiming the skill helped.
- **Stop when**: the benchmark task shows no new failures AND the dataset has no uncovered topics AND all testable claims have passing tests.

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

These commands use `nim-ownership-hooks` as a concrete example.
On Nim 2.2+ the baseline `nim c -r --mm:orc` run already uses `threads:on`, so treat that as the default path and add `--threads:off` only when a claim explicitly depends on `compileOption("threads")`.

```bash
cd tests/nim-ownership-hooks_verification

# Run all positive tests on the default ORC configuration
for f in test_*.nim; do
  case "$f" in
    *_bad*.nim|*_negative*.nim) continue ;;
  esac
  nim c -r --mm:orc "$f"
done

# Negative test (should fail to compile)
nim c --mm:orc test_c16_order_bad_generic.nim && exit 1

# Thread-switch-sensitive claim: compare default ORC vs explicit single-threaded mode
nim c -r --mm:orc test_c39_thread_alloc_switch.nim
nim c -r --mm:orc --threads:off test_c39_thread_alloc_switch.nim

# Inspect compiler hook insertions
nim c --mm:orc --expandArc:main <test_file>

# Optional deeper leak check for manual-memory claims, only after the normal test passes
# AddressSanitizer example validated in this repo on test_c35_copy_nil_guard.nim
nim c --mm:orc --passC:-fsanitize=address --passL:-fsanitize=address test_c35_copy_nil_guard.nim
./test_c35_copy_nil_guard

# Valgrind example validated in this repo on the same test
nim c --mm:orc -o:test_c35_copy_nil_guard_plain test_c35_copy_nil_guard.nim
valgrind --leak-check=full --error-exitcode=1 ./test_c35_copy_nil_guard_plain
```

Tested with **Nim 2.3.1** and `--mm:orc`. In this environment, the default ORC run reports `threads: on`. The ASan and Valgrind recipes above were both confirmed on `test_c35_copy_nil_guard.nim`.
