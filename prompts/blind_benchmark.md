# Prompt Template: Blind Benchmark

## Purpose
Compare two versions of a skill file using a double-blind methodology where the evaluator does not know which version produced which output.

## Inputs
- `ORIGINAL_SKILL`: path to `original_skills/{SKILL_NAME}/SKILL.md`
- `VERIFIED_SKILL`: path to `skills/{SKILL_NAME}/SKILL.md`
- `TASK_SPEC`: a task prompt that specifies exact types, signatures, and compilation requirements
- `NUM_TRIALS`: trials per group (default: 3)

## Instructions

### Step 1: Prepare blind labels

1. Create directory `blind_trials/` (or reuse existing)
2. Create `blind_trials/group_x_skill.md` — copy one skill file
3. Create `blind_trials/group_y_skill.md` — copy the other skill file
4. **Do NOT record which is which in any file.** The mapping must exist only in your transient memory.
5. Create `blind_trials/task.txt` — the task specification
6. Create isolated directories: `blind_trials/A{1..N}` and `blind_trials/B{1..N}`

### Step 2: Spawn generator subagents

Spawn `2 × NUM_TRIALS` subagents. Each must:
- Read its assigned skill file (`group_x_skill.md` or `group_y_skill.md`)
- Read `task.txt` for the implementation requirements
- Write output to an **absolute path** (e.g., `/full/path/blind_trials/A1/solution.nim`)
- Verify compilation after writing

Group A (A1-AN) reads `group_x_skill.md`. Group B (B1-BN) reads `group_y_skill.md`.

**Critical**: each subagent writes to its own isolated directory with an absolute path. Do not rely on `cwd` inheritance — use explicit absolute paths in the task message.

### Step 3: Evaluate blindly

After ALL subagents complete, evaluate each trial against fixed criteria:

1. **COMPILE** — compiles with `--mm:orc`
2. **HOOK_SIGS** — `=destroy` takes `T` (not `var T`), `=wasMoved` takes `var T`
3. **NO_NIL** — no field assignments inside `=destroy`
4. **SELF_ASSIGN** — `=copy` handles self-assignment (either via guard or counter balance)
5. **NODUP** — `=dup` is correct: uses `{.nodestroy.}` OR refcount balances; increments source counter
6. **COW** — `mutateAt` implements copy-on-write when counter > 0 (or > 1 depending on convention)
7. **STRESS** — passes stress test suite (refcount, CoW, self-copy, move, empty string)
8. **MEMORY_SAFE** — Valgrind/ASan clean
9. **DESTROY_COUNTER** — `=destroy` checks counter value (not just nil) for refcounted types
10. **THREAD_SAFE** — uses `when compileOption("threads")` to switch alloc/dealloc

Write `verdict.json` per trial. Aggregate by group.

### Step 4: Unblind and report

Reveal which skill is Group X and which is Group Y. Write `benchmarking_results.md` with:
- Blind results table (pre-unblinding)
- Unblinded results with skill names
- Aggregate comparison
- Analysis of differences
- Statistical note (n=3 is insufficient for firm conclusions)

### Step 5: Feed back

If the benchmark reveals deficiencies in the skill:
1. Note specific failures and their root causes
2. Add new claims to the dataset (feed back to Phase 1)
3. Do NOT immediately rewrite the skill — let the next cycle handle it through the full Phase 1→4 pipeline

### Key rules

- **No result poisoning**: evaluator does not know group assignments during Step 3
- **Absolute paths**: subagents write to absolute paths, not relative cwd
- **Simple pipeline**: Generator → Evaluator. No intermediate phases.
- **Sample size**: 3 minimum per group, 10+ for significance

## Reusability
Replace `{SKILL_NAME}`, `{ORIGINAL_SKILL}`, `{VERIFIED_SKILL}`, and `{TASK_SPEC}` for each skill being benchmarked.
