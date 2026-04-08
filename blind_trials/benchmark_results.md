# Benchmark Results — nim-api-design (Unblinded)

## Hidden Mapping
- **Verified skill** → runs 01, 04, 05
- **Original skill** → runs 02, 03, 06

## Scores by Group

### Verified skill (runs 01, 04, 05)
| Run  | Score | Failure |
|------|-------|---------|
| 01   | 12/13 | error helper exported (has *) |
| 04   | 13/13 | — |
| 05   | 13/13 | — |
| **Avg** | **12.7/13** | |

### Original skill (runs 02, 03, 06)
| Run  | Score | Failure |
|------|-------|---------|
| 02   | 13/13 | — |
| 03   | 13/13 | — |
| 06   | 12/13 | error helper exported (has *) |
| **Avg** | **12.7/13** | |

## Summary

Both skills performed identically: **12.7/13 average**. The task was well-specified
enough that both skills guided workers to correct solutions. The only failure mode
was the same in both groups: exporting the error helper proc (rubric item 10 —
"shared **private** {.noinline, noreturn.} helper").

### Failure mode analysis
Both run_01 (verified) and run_06 (original) exported `raisePackageNotFound*`
instead of keeping it private. This is a task-spec compliance issue, not a
skill quality issue — the task explicitly says "one shared private helper" but
workers still exported it.

### Conclusion
The benchmark shows **no meaningful difference** between original and verified
skill on this task. The task was strongly specified (exact type signatures,
exact proc names, exact behavior), which left little room for the verified
skill's additional guidance to help. The verified skill would likely show
advantage on less-specified tasks where the coder must make API design
decisions independently.
