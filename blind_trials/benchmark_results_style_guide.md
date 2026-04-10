# Benchmark Results: nim-style-guide

**Date:** 2026-04-09
**Task:** Rule parser module (style-focused)
**Trials per arm:** 3
**Checklist items:** 12

## Unblinded Mapping

| Trial Directory | Arm |
|---|---|
| trial_074f7101 | original |
| trial_078a66ca | original |
| trial_7746a6b4 | original |
| trial_7583185e | verified |
| trial_120228be | verified |
| trial_20872ab2 | verified |
| trial_b89d51bc | no-skill |
| trial_5b64be9e | no-skill |
| trial_4e15801f | no-skill |

## Checklist Items

1. Compiles and runs with `nim c -r --mm:orc subject_solution.nim`
2. Runtime prints `SMOKE: PASS`
3. `open`, `next`, `close`, `renderSummary` match required behavior
4. Accepted rules preserve order, counters correct
5. Exported surface contains required public symbols, no extra exported internals
6. No `continue` statement
7. No `type` block inside a proc
8. Helpers with control flow are `proc`/`func`, not `template`
9. Helper procs are top-level, not nested inside exported procs
10. No one-argument-per-line call blocks where compact wrapped would fit
11. Object construction does not restate defaulted fields when defaults intended
12. No unused imports

## Per-Trial Scores

### original arm

**trial_074f7101** — 12/12
| # | Check | Result |
|---|---|---|
| 1 | Compiles and runs | ✅ |
| 2 | SMOKE: PASS | ✅ |
| 3 | Behavior correct | ✅ |
| 4 | Order/counters correct | ✅ |
| 5 | Clean exported surface | ✅ |
| 6 | No `continue` | ✅ |
| 7 | No nested type block | ✅ |
| 8 | Helpers are proc/func | ✅ |
| 9 | Helpers top-level | ✅ |
| 10 | Compact call style | ✅ |
| 11 | No restated defaults | ✅ |
| 12 | No unused imports | ✅ |

**trial_078a66ca** — 12/12
| # | Check | Result |
|---|---|---|
| 1 | Compiles and runs | ✅ |
| 2 | SMOKE: PASS | ✅ |
| 3 | Behavior correct | ✅ |
| 4 | Order/counters correct | ✅ |
| 5 | Clean exported surface | ✅ |
| 6 | No `continue` | ✅ |
| 7 | No nested type block | ✅ |
| 8 | Helpers are proc/func | ✅ |
| 9 | Helpers top-level | ✅ |
| 10 | Compact call style | ✅ |
| 11 | No restated defaults | ✅ |
| 12 | No unused imports | ✅ |

**trial_7746a6b4** — 11/12
| # | Check | Result |
|---|---|---|
| 1 | Compiles and runs | ✅ |
| 2 | SMOKE: PASS | ✅ |
| 3 | Behavior correct | ✅ |
| 4 | Order/counters correct | ✅ |
| 5 | Clean exported surface | ✅ |
| 6 | No `continue` | ✅ |
| 7 | No nested type block | ✅ |
| 8 | Helpers are proc/func | ✅ |
| 9 | Helpers top-level | ✅ |
| 10 | Compact call style | ✅ |
| 11 | No restated defaults | ❌ — `pos: 0` restates int default |
| 12 | No unused imports | ✅ |

### verified arm

**trial_7583185e** — 12/12
| # | Check | Result |
|---|---|---|
| 1 | Compiles and runs | ✅ |
| 2 | SMOKE: PASS | ✅ |
| 3 | Behavior correct | ✅ |
| 4 | Order/counters correct | ✅ |
| 5 | Clean exported surface | ✅ |
| 6 | No `continue` | ✅ |
| 7 | No nested type block | ✅ |
| 8 | Helpers are proc/func | ✅ |
| 9 | Helpers top-level | ✅ |
| 10 | Compact call style | ✅ |
| 11 | No restated defaults | ✅ |
| 12 | No unused imports | ✅ |

**trial_120228be** — 12/12
| # | Check | Result |
|---|---|---|
| 1 | Compiles and runs | ✅ |
| 2 | SMOKE: PASS | ✅ |
| 3 | Behavior correct | ✅ |
| 4 | Order/counters correct | ✅ |
| 5 | Clean exported surface | ✅ |
| 6 | No `continue` | ✅ |
| 7 | No nested type block | ✅ |
| 8 | Helpers are proc/func | ✅ |
| 9 | Helpers top-level | ✅ |
| 10 | Compact call style | ✅ |
| 11 | No restated defaults | ✅ |
| 12 | No unused imports | ✅ |

**trial_20872ab2** — 12/12
| # | Check | Result |
|---|---|---|
| 1 | Compiles and runs | ✅ |
| 2 | SMOKE: PASS | ✅ |
| 3 | Behavior correct | ✅ |
| 4 | Order/counters correct | ✅ |
| 5 | Clean exported surface | ✅ |
| 6 | No `continue` | ✅ |
| 7 | No nested type block | ✅ |
| 8 | Helpers are proc/func | ✅ |
| 9 | Helpers top-level | ✅ |
| 10 | Compact call style | ✅ |
| 11 | No restated defaults | ✅ |
| 12 | No unused imports | ✅ |

### no-skill arm

**trial_b89d51bc** — 11/12
| # | Check | Result |
|---|---|---|
| 1 | Compiles and runs | ✅ |
| 2 | SMOKE: PASS | ✅ |
| 3 | Behavior correct | ✅ |
| 4 | Order/counters correct | ✅ |
| 5 | Clean exported surface | ❌ — `lines*` and `pos*` exported, should be private |
| 6 | No `continue` | ✅ |
| 7 | No nested type block | ✅ |
| 8 | Helpers are proc/func | ✅ |
| 9 | Helpers top-level | ✅ |
| 10 | Compact call style | ✅ |
| 11 | No restated defaults | ✅ |
| 12 | No unused imports | ✅ |

**trial_5b64be9e** — 12/12
| # | Check | Result |
|---|---|---|
| 1 | Compiles and runs | ✅ |
| 2 | SMOKE: PASS | ✅ |
| 3 | Behavior correct | ✅ |
| 4 | Order/counters correct | ✅ |
| 5 | Clean exported surface | ✅ |
| 6 | No `continue` | ✅ |
| 7 | No nested type block | ✅ |
| 8 | Helpers are proc/func | ✅ |
| 9 | Helpers top-level | ✅ |
| 10 | Compact call style | ✅ |
| 11 | No restated defaults | ✅ |
| 12 | No unused imports | ✅ |

**trial_4e15801f** — 12/12
| # | Check | Result |
|---|---|---|
| 1 | Compiles and runs | ✅ |
| 2 | SMOKE: PASS | ✅ |
| 3 | Behavior correct | ✅ |
| 4 | Order/counters correct | ✅ |
| 5 | Clean exported surface | ✅ |
| 6 | No `continue` | ✅ |
| 7 | No nested type block | ✅ |
| 8 | Helpers are proc/func | ✅ |
| 9 | Helpers top-level | ✅ |
| 10 | Compact call style | ✅ |
| 11 | No restated defaults | ✅ |
| 12 | No unused imports | ✅ |

## Aggregate Scores

| Arm | Trial 1 | Trial 2 | Trial 3 | Average | Perfect (12/12) |
|---|---|---|---|---|---|
| **original** | 12/12 | 12/12 | 11/12 | **11.67** | 2/3 |
| **verified** | 12/12 | 12/12 | 12/12 | **12.00** | 3/3 |
| **no-skill** | 11/12 | 12/12 | 12/12 | **11.67** | 2/3 |

## Style Details by Failure

| Trial | Arm | Failed Check | Detail |
|---|---|---|---|
| trial_7746a6b4 | original | #11 restated defaults | `pos: 0` in constructor restates the int default |
| trial_b89d51bc | no-skill | #5 exported surface | `lines*` and `pos*` use `*` making internals public |

## Notable Style Observations

### Helpers: `func` vs `proc` usage
- **verified arm**: All 3 trials used `func` for pure helpers (`isValidKey`, `isValidValue`, `containsOnly`, `trimLine`, `isComment`, `validChars`). This aligns with the verified skill's explicit guidance to "Use `func` for side-effect-free helpers."
- **original arm**: 2 of 3 used `proc` for pure helpers; 1 (trial_074f7101) used a callback-proc pattern (`isValidToken(s, valid: proc(c: char): bool)`). None used `func`.
- **no-skill arm**: 2 of 3 used `func` for pure helpers. 1 used `proc`.

### Decomposition patterns
- **verified arm**: More varied decomposition — `parseRule` helper returning a tuple (trial_120228be), `trimLine` func (trial_20872ab2), `containsOnly` func (trial_7583185e).
- **original arm**: More uniform — all used a single validation proc with similar structure.
- **no-skill arm**: Mixed patterns, including `count()` + `split()` approach (trial_20872ab2 rerun equivalent was trial_b89d51bc which used `find` twice).

### `close` implementation
- Most trials used `p = RuleParser()`. One no-skill trial (trial_b89d51bc) used `p = default(RuleParser)`. Both achieve the same reset.

## Interpretation

This was a **style-focused** benchmark where all arms produced functionally correct code. The differences are purely in style adherence:

1. **Verified skill (12.00 avg)** achieved perfect scores across all 3 trials. The explicit guidance on `func` vs `proc` and object constructor defaults translated directly into cleaner code.

2. **Original skill (11.67 avg)** dropped one point on restating a default (`pos: 0`). The original skill mentions "Prefer object-construction syntax over field-by-field" but doesn't explicitly call out not restating defaults, which the verified skill does.

3. **No-skill (11.67 avg)** dropped one point on exporting internal fields (`lines*`, `pos*`). Without style guidance, the model didn't distinguish between the public API surface and internal state.

The effect sizes are small (0.33 points on a 12-point scale) because this task is well within the model's competence. The style guide's strongest signal was on `func` usage for pure helpers — the verified arm consistently used `func` while other arms were mixed. The "don't restate defaults" and "keep internals private" rules each caught one violation in the other arms.

**Bottom line:** The verified skill produced marginally more consistent style adherence. With only 3 trials per arm, the difference between 11.67 and 12.00 is not statistically meaningful, but the verified arm was the only one with zero style violations across all trials.
