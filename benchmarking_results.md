# Blind Benchmarking Results

## Methodology

**Double-blind**: 6 subagent trials spawned, labeled A1-A3 and B1-B3. Group A received one skill file, Group B received another. The evaluator did not know which skill corresponded to which group during evaluation.

Each subagent:
1. Read its assigned skill file
2. Implemented `subject_solution.nim` (refcounted CoW String)
3. Verified compilation with `nim c --mm:orc`

Evaluation criteria (8 per trial):
1. **COMPILE** — compiles with `--mm:orc`
2. **HOOK_SIGS** — `=destroy` takes `T` (not `var T`), `=wasMoved` takes `var T`
3. **NO_NIL** — no field assignments inside `=destroy` (that's `=wasMoved`'s job)
4. **SELF_ASSIGN** — `=copy` has self-assignment protection
5. **NODUP** — `=dup` uses `{.nodestroy.}`
6. **COW** — `mutateAt` implements copy-on-write when counter > 1
7. **STRESS** — passes stress tests (refcount, CoW, self-copy, move, empty string)
8. **MEMORY_SAFE** — Valgrind reports 0 errors, 0 leaks

## Blind Results (pre-unblinding)

| Trial | COMPILE | HOOKS | NO_NIL | SELF | NODUP | COW | STRESS | MEMSAFE | Score |
|-------|---------|-------|--------|------|-------|-----|--------|---------|-------|
| A1    | ✅      | ✅    | ✅     | ✅   | ✅    | ✅  | ✅     | ✅      | 8/8   |
| A2    | ✅      | ✅    | ✅     | ✅   | ✅    | ✅  | ❌     | ⏭️      | 7/8   |
| A3    | ✅      | ✅    | ✅     | ✅   | ✅    | ✅  | ✅     | ✅      | 8/8   |
| B1    | ✅      | ✅    | ✅     | ✅   | ✅    | ✅  | ✅     | ✅      | 8/8   |
| B2    | ✅      | ✅    | ✅     | ✅   | ✅    | ✅  | ❌     | ⏭️      | 7/8   |
| B3    | ✅      | ❌    | ✅     | ✅   | ✅    | ✅  | ❌     | ⏭️      | 6/8   |

### Failure details

- **A2 STRESS**: Empty string `initString("")` causes index out of bounds — missing guard for zero-length data in initString
- **B2 STRESS**: Same empty string bug — index out of bounds
- **B3 HOOK_SIGS**: `=destroy` takes `x: var String` instead of `x: String`
- **B3 STRESS**: Same empty string bug

### Group aggregates (blind)

| Group | Avg Score | Perfect 8/8 | Hook Sig Failures | Stress Failures |
|-------|-----------|-------------|-------------------|-----------------|
| A     | 7.67/8    | 2/3         | 0                 | 1               |
| B     | 7.00/8    | 1/3         | 1                 | 2               |

## Unblinding

Group **A** used: `original_skills/nim-ownership-hooks/SKILL.md` — human-written skill
Group **B** used: `skills/nim-ownership-hooks/SKILL.md` — AI-verified skill

### Unblinded Results

| Skill Version | Trial | Score | Key Issues |
|---------------|-------|-------|------------|
| **Original** (Group A) | A1 | 8/8 | None |
| **Original** (Group A) | A2 | 7/8 | Empty string guard missing |
| **Original** (Group A) | A3 | 8/8 | None |
| **Verified** (Group B) | B1 | 8/8 | None |
| **Verified** (Group B) | B2 | 7/8 | Empty string guard missing |
| **Verified** (Group B) | B3 | 6/8 | Wrong =destroy signature + empty string guard |

### Aggregate Comparison

| Metric | Original Skill | Verified Skill |
|--------|---------------|----------------|
| Avg score | 7.67/8 | 7.00/8 |
| Perfect scores | 2/3 (67%) | 1/3 (33%) |
| Hook signature errors | 0 | 1 |
| Stress test failures | 1 | 2 |

## Analysis

The results are **inconclusive for a definitive superiority claim**. Both skill versions produce mostly correct code, with the primary failure mode (empty string guard) being orthogonal to the skill content — neither skill explicitly addresses zero-length edge cases in `initString`.

The one meaningful difference: **B3 used `var String` in `=destroy`** (a hook signature error). The verified skill's code examples were corrected to use `T` not `var T`, yet one subagent still produced the wrong signature. This suggests the skill content alone doesn't guarantee correct hook signatures — the LLM may override skill guidance with its own training data patterns.

The sample size (3 per group) is too small for statistical significance. A larger trial (10+ per group) would be needed to draw firm conclusions about skill quality differences.
