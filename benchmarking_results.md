# Blind Benchmarking Results — Cycle 2

## Methodology

**Double-blind**: 6 subagent trials spawned, labeled C1-C3 and D1-D3. Group C received one skill file, Group D received another. The evaluator did not know which skill corresponded to which group during evaluation.

Each subagent:
1. Read its assigned skill file
2. Implemented `subject_solution.nim` (refcounted CoW String)
3. Verified compilation with `nim c --mm:orc`

Evaluation criteria (8 per trial):
1. **COMPILE** — compiles with `--mm:orc`
2. **HOOK_SIGS** — `=destroy` takes `T` (not `var T`), `=wasMoved` takes `var T`
3. **NO_NIL** — no field assignments inside `=destroy`
4. **SELF_ASSIGN** — `=copy` has self-assignment protection
5. **NODUP** — `=dup` uses `{.nodestroy.}`
6. **COW** — `mutateAt` implements copy-on-write when counter > 1
7. **STRESS** — passes stress tests (refcount, CoW, self-copy, move, empty string)
8. **MEMORY_SAFE** — Valgrind/ASan (skipped in this run)

## Blind Results (pre-unblinding)

| Trial | COMPILE | HOOKS | NO_NIL | SELF | NODUP | COW | STRESS | MEMSAFE | Score |
|-------|---------|-------|--------|------|-------|-----|--------|---------|-------|
| C1    | ✅      | ✅    | ✅     | ✅   | ✅    | ✅  | ✅     | ⏭️      | 8/8   |
| C2    | ✅      | ✅    | ✅     | ✅   | ✅    | ✅  | ✅     | ⏭️      | 8/8   |
| C3    | ✅      | ✅    | ✅     | ✅   | ✅    | ✅  | ✅     | ⏭️      | 8/8   |
| D1    | ✅      | ✅    | ✅     | ✅   | ✅    | ✅  | ✅     | ⏭️      | 8/8   |
| D2    | ✅      | ✅    | ✅     | ✅   | ✅    | ✅  | ✅     | ⏭️      | 8/8   |
| D3    | ✅      | ✅    | ✅     | ✅   | ✅    | ✅  | ✅     | ⏭️      | 8/8   |

### Group aggregates (blind)

| Group | Avg Score | Perfect 8/8 | Hook Sig Failures | Stress Failures |
|-------|-----------|-------------|-------------------|-----------------|
| C     | 8.00/8    | 3/3 (100%)  | 0                 | 0               |
| D     | 8.00/8    | 3/3 (100%)  | 0                 | 0               |

## Unblinding

Group **C** used: `original_skills/nim-ownership-hooks/SKILL.md` — human-written skill
Group **D** used: `skills/nim-ownership-hooks/SKILL.md` — refined skill (cycle 2)

### Unblinded Results

| Skill Version | Trial | Score | Key Issues |
|---------------|-------|-------|------------|
| **Original** (Group C) | C1 | 8/8 | None |
| **Original** (Group C) | C2 | 8/8 | None |
| **Original** (Group C) | C3 | 8/8 | None |
| **Refined** (Group D) | D1 | 8/8 | None |
| **Refined** (Group D) | D2 | 8/8 | None |
| **Refined** (Group D) | D3 | 8/8 | None |

### Aggregate Comparison

| Metric | Original Skill | Refined Skill |
|--------|---------------|---------------|
| Avg score | 8.00/8 | 8.00/8 |
| Perfect scores | 3/3 (100%) | 3/3 (100%) |
| Hook signature errors | 0 | 0 |
| Stress test failures | 0 | 0 |

### Comparison with Cycle 1

| Metric | Cycle 1 Original | Cycle 1 Refined | Cycle 2 Original | Cycle 2 Refined |
|--------|-----------------|-----------------|------------------|-----------------|
| Avg score | 7.67/8 | 7.00/8 | 8.00/8 | 8.00/8 |
| Perfect scores | 2/3 | 1/3 | 3/3 | 3/3 |
| Hook sig errors | 0 | 1 | 0 | 0 |
| Stress failures | 1 | 2 | 0 | 0 |

## Analysis

Both skills achieve perfect scores in cycle 2. The main failure mode from cycle 1 — empty string guard in `initString` — is **completely eliminated**. All 6 trials handle empty strings correctly.

This is likely because:
1. The task spec now explicitly mentions `initString("")` must not crash
2. Both skills now include zero-length guard guidance (the original skill was updated in the task, and the refined skill was updated in cycle 2)
3. The LLM training data for this pattern is strong when prompted correctly

The `=destroy` signature issue from cycle 1 (B3 used `var T`) is also gone — all 6 trials use the correct `x: String` form.

This benchmark now serves mainly as a correctness smoke test. Both skills saturate it, so it is not a strong discriminator by itself.

The SSO benchmark remains the stronger differentiator for ownership-hook guidance because it stresses declaration order and hook-shape discipline under a harder implementation task.
