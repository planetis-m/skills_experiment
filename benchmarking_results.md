# Benchmarking Results

## Methodology

Prompt-driven subagent orchestration. 6 trials (3 per skill version).
Task: implement a refcounted CoW `String` type in Nim with `=destroy`, `=wasMoved`, `=dup`, `=copy` hooks.

**Pipeline phases:**
1. Generator → produces `subject_solution.nim` + `stress_test.nim`
2. Executor → compiles with `--mm:orc -d:useMalloc`, runs binaries
3. Validator → Valgrind memcheck (0 errors, 0 leaks required)
4. Judge → 8-criteria evaluation (compile, hook signatures, code quality, memory safety)

**Environment:** Nim 2.3.1, `--mm:orc`, Valgrind 3.24.0

## Results Summary

| Trial | Version | Compile | Hook Sigs | No nil in destroy | Self-assign | Nodup | CoW | Stress | Memory Safe | Score |
|-------|---------|---------|-----------|-------------------|-------------|-------|-----|--------|-------------|-------|
| original_1 | original | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 8/8 |
| original_2 | original | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 8/8 |
| original_3 | original | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 8/8 |
| verified_1 | verified | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 8/8 |
| verified_2 | verified | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 8/8 |
| verified_3 | verified | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 8/8 |

## Aggregate Scores

| Skill Version | Trials | Avg Score | Memory Safe |
|---------------|--------|-----------|-------------|
| Original (no rules) | 3 | 8/8 (100%) | 3/3 |
| Verified (rules injected) | 3 | 8/8 (100%) | 3/3 |

## Stress Test Coverage

All 6 trials passed stress tests covering:
1. **Repeated allocation** — 1000× init/copy/mutate/destroy cycle
2. **Self-aliasing** — `=copy(s, s)` preserves data and counter
3. **Mutation-after-move** — moved-from source has `p == nil`, no crash on mutation attempt
4. **Deep copy chain** — a→b→c, mutate c, verify a and b unchanged via CoW
5. **Counter accuracy** — 100 copies, shrink seq to 1, verify counter=2
6. **Empty string** — initString with "", getStr returns ""

## Memory Safety

Valgrind results for all 6 trials:
```
ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)
definitely lost: 0 bytes in 0 blocks
```

No memory leaks, no double frees, no invalid reads/writes.

## Analysis

Both skill versions produce **identically correct** implementations when the task specification is precise and the required hook signatures are provided in the prompt. The verified skill's primary value is in its **code examples and rules** — it prevents the `x.p = nil` inside `=destroy` bug and the `var T` in `=destroy` signature that appeared in the original skill's code blocks.

The key difference between the skills is **defensive**: the verified skill explicitly states rules that prevent common mistakes, while the original skill's code examples contained those mistakes. When LLMs are given precise signatures in the task prompt, both perform equally. When LLMs copy from skill code examples, the verified skill's examples are correct while the original's contained bugs.

## Corrections Applied to Verified Skill

1. `=destroy` signature changed from `x: var T` to `x: T` in all code examples
2. Removed all `x.data = nil` / `x.p = nil` from `=destroy` bodies
3. Added explicit rule: "Never set fields to nil inside `=destroy` — that is `=wasMoved`'s job"
