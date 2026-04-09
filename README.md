# Skills Experiment

Empirically verified Nim coding skills, test suites, datasets, and benchmarks.

## Overview

This repository contains a small prompt-driven pipeline for auditing, verifying, and refining Nim coding skills with datasets, tests, and benchmark tasks.

Start at `prompts/README.md`. Use the smallest prompt that matches the job.

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

### Benchmark prerequisites

For OpenClaw, benchmark runs require this config change:

```json
"agents": {
  "defaults": {
    "subagents": {
      "maxSpawnDepth": 2
    }
  }
}
```

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

```text
┌──────────────────────────────────────────────┐
│  Refinement Loop                             │
│                                              │
│  Phase 1: Extract NEW claims only            │
│     ↓                                        │
│  Phase 2: Write tests for UNTESTED claims    │
│     ↓                                        │
│  Phase 3: Re-curate ALL claims               │
│     ↓                                        │
│  Phase 4: Targeted edits to verified skill   │
│     ↓                                        │
│  Benchmark: Re-run task comparison           │
│     ↓                                        │
│  ┌─── Feed failures back to Phase 1 ───┐     │
│  └─────────────────────────────────────┘     │
│                                              │
│  Repeat until no new failures or gaps remain │
└──────────────────────────────────────────────┘
```

Operational rules:
- Phase 1: Extract only new claims.
- Phase 2: Add tests only for untested or under-tested claims.
- Phase 3: Re-curate the whole dataset.
- Phase 4: Make targeted edits to the verified skill.
- Revisit `prompts/benchmark_task_design.md` if the benchmark is too tight, too easy, or too weakly scored.
- Re-run the relevant benchmark or task comparison.
- Feed new failures back into Phase 1.

### What triggers a refinement cycle

- User explicitly asks to improve a skill
- New Nim version changes behavior (re-run tests, check for regressions)
- Benchmark reveals deficiencies in the verified skill
- The dataset has `uncovered_topics` or `needs_stronger_tests` entries

## Prompt Templates

Prompts in [`prompts/`](/home/ageralis/skills_experiment/prompts) are parameterized with these variables:

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
