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

1. Create directory `blind_trials/`
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
2. **HOOK_SIGS** — correct hook signatures
3. **NO_NIL** — no field mutation inside `=destroy`
4. **SELF_ASSIGN** — self-assignment protection in `=copy`
5. **NODUP** — `{.nodestroy.}` on `=dup`
6. **COW** — copy-on-write implemented
7. **STRESS** — passes stress test suite
8. **MEMORY_SAFE** — Valgrind/ASan clean

Write `verdict.json` per trial. Aggregate by group.

### Step 4: Unblind and report

Reveal which skill is Group X and which is Group Y. Write `blind_results.md` with:
- Blind results table (pre-unblinding)
- Unblinded results with skill names
- Aggregate comparison
- Analysis of differences
- Statistical note (n=3 is insufficient for firm conclusions)

### Key rules

- **No result poisoning**: evaluator does not know group assignments during Step 3
- **Absolute paths**: subagents write to absolute paths, not relative cwd
- **Simple pipeline**: Generator → Evaluator. No intermediate phases.
- **Sample size**: 3 minimum per group, 10+ for significance

## Reusability
Replace `{SKILL_NAME}`, `{ORIGINAL_SKILL}`, `{VERIFIED_SKILL}`, and `{TASK_SPEC}` for each skill being benchmarked.
