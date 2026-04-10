# Style Guide Benchmark Results

**Date:** 2026-04-09  
**Task:** nim-style-guide categorizer (`blind_trials/task_style_guide.txt`)  
**Model:** zai/glm-5.1  
**Trials per arm:** 3  
**Arms:** original, verified, no-skill  
**Workers:** 9 independent subagents

## Arm Assignments (unblinded)

| Trial | Arm | Score | Notes |
|-------|-----|-------|-------|
| sg_bench_1 | original | 12/12 | Clean |
| sg_bench_5 | original | 0/12 | Worker produced no file (failed generation) |
| sg_bench_8 | original | 12/12 | Clean |
| sg_bench_3 | verified | 12/12 | Clean |
| sg_bench_4 | verified | 12/12 | Clean |
| sg_bench_9 | verified | 12/12 | Clean |
| sg_bench_2 | no-skill | 12/12 | Clean |
| sg_bench_6 | no-skill | 0/12 | Worker produced no file (failed generation) |
| sg_bench_7 | no-skill | 12/12 | Clean |

## Per-Arm Averages

| Arm | Avg (all trials) | Avg (completed only) |
|-----|-------------------|----------------------|
| verified | **12.0/12** (100%) | 12.0/12 (100%) |
| original | **8.0/12** (67%) | 12.0/12 (100%) |
| no-skill | **8.0/12** (67%) | 12.0/12 (100%) |

## Verified vs Original

Among completed trials: identical (12/12 each). The one original-arm failure (sg_bench_5) was a worker that produced zero output — likely an API/startup glitch, not a skill issue.

## Verified vs No-Skill

Among completed trials: identical (12/12 each). The one no-skill failure (sg_bench_6) was also a zero-output worker.

## Original vs No-Skill

Identical among completed trials.

## Per-Trial Checklist Detail

All 7 completed trials (sg_bench_1, 2, 3, 4, 7, 8, 9) scored identically:

| # | Check | Result |
|---|-------|--------|
| 1 | Compiles and runs with `nim c -r --mm:orc` | ✅ PASS |
| 2 | Prints `SMOKE: PASS` | ✅ PASS |
| 3 | Strict mode raises on empty trimmed items | ✅ PASS |
| 4 | Lenient mode skips and counts in `skipped` | ✅ PASS |
| 5 | Accepted items preserve order after trimming | ✅ PASS |
| 6 | Required public symbols, no extra exports | ✅ PASS |
| 7 | No `continue` statement | ✅ PASS |
| 8 | No `type` block inside a proc | ✅ PASS |
| 9 | Helpers with control flow are `proc`/`func`, not `template` | ✅ PASS |
| 10 | No one-argument-per-line call blocks | ✅ PASS |
| 11 | Object construction omits defaulted fields | ✅ PASS |
| 12 | No unused imports | ✅ PASS |

## Concrete Mistakes

### Failed generations (not style mistakes)
- **sg_bench_5** (original arm): Worker completed with zero tokens output. No file written. Likely a model/API startup issue, not a skill quality problem.
- **sg_bench_6** (no-skill arm): Same — zero output, no file written.

### Style observations (non-scoring)
- sg_bench_2 and sg_bench_7 (both no-skill) placed the `type` block before the `import`. This is unconventional but not on the checklist, so it wasn't scored.
- sg_bench_2 added an unnecessary `func trim(s: string): string = s.strip()` wrapper — dead wrapper around a single call, but not a checklist violation.
- All completed solutions are structurally almost identical: same logic, same `ParseSummary(mode: mode)` constructor pattern, same loop structure. The model strongly converges on one canonical solution for this task.

## Interpretation

Per the interpretation rules:

- **All arms perform similarly well** → the task is too easy or too specified for this model. The checklist anti-patterns (continue, template misuse, type-in-proc, unused imports, restating defaults) are things zai/glm-5.1 avoids by default on a simple task like this.
- The checklist is well-designed (it checks real style issues) but this task doesn't stress it — there are too few decisions for the model to make mistakes on.
- The 2 failed generations are infrastructure issues, not skill issues.
- To properly discriminate between original, verified, and no-skill, the task needs more surface area — more helpers, more construction sites, more places where style choices diverge.
