# SSO String Benchmark Results

## Task

Implement an SSO (Small String Optimization) `String` type with bit-punning, union types, short/long mode switching, heap allocation for long strings, and inline storage for short strings.

## Blind Results (pre-unblinding)

| Trial | COMPILE | HOOKS | NO_NIL | SELF | NODUP | COW | STRESS | COUNTER | THREADS | Score |
|-------|---------|-------|--------|------|-------|-----|--------|---------|---------|-------|
| E1    | ❌      | —     | —      | —    | —     | —   | —      | —       | —       | 0/10  |
| E2    | ❌      | —     | —      | —    | —     | —   | —      | —       | —       | 0/10  |
| E3    | ❌      | —     | —      | —    | —     | —   | —      | —       | —       | 0/10  |
| F1    | ✅      | ✅    | ✅     | ✅   | ✅    | —   | ✅     | ✅      | ✅      | 8/10  |
| F2    | ✅      | ✅    | ✅     | ✅   | ✅    | —   | ✅     | ✅      | ❌      | 7/10  |
| F3    | ✅      | ✅    | ✅     | ✅   | ✅    | —   | ✅     | ✅      | ✅      | 8/10  |

### Failure details

- **E1/E2/E3**: Declaration order error. `=dup` body contains `result = String.default` which triggers implicit `=copy` generation. The explicit `=copy` declared after `=dup` conflicts: `Error: cannot bind another '=copy' to: String`
- **F2**: Missing `when compileOption("threads")` switch — uses bare `dealloc` always

### Group aggregates (blind)

| Group | Compile Rate | Avg Score | Key Failure |
|-------|-------------|-----------|-------------|
| E     | 0/3 (0%)    | 0/10      | Declaration order (=dup before =copy) |
| F     | 3/3 (100%)  | 7.67/10   | Thread safety (1/3 missing) |

## Unblinding

Group **E** used: `original_skills/nim-ownership-hooks/SKILL.md` — human-written skill
Group **F** used: `skills/nim-ownership-hooks/SKILL.md` — refined skill

## Analysis

**The refined skill dominates on this benchmark.**

The critical difference: the original skill mentions declaration order as a rule but doesn't emphasize the specific pitfall of `=dup` triggering implicit `=copy` generation. The refined skill has a clearer workflow with explicit ordering: `=destroy`, `=wasMoved`, `=copy`, then `=dup` — and the code examples show `=copy` declared before `=dup`.

All 3 E-group agents declared hooks in the order: `=destroy`, `=wasMoved`, `=dup`, `=copy` — putting `=dup` before `=copy`. This is fatal because `=dup`'s body (assigning to `result`) triggers the compiler to generate an implicit `=copy`, which then conflicts with the later explicit `=copy`.

All 3 F-group agents either declared `=copy` before `=dup` or avoided triggering implicit `=copy` in `=dup`'s body.

With `n=3`, this is strong directional evidence rather than a final statistical result. The refined skill's emphasis on declaration order workflow directly prevented a catastrophic class of errors.

## Comparison across all benchmarks

| Benchmark | Original Skill | Refined Skill | Key Differentiator |
|-----------|---------------|---------------|-------------------|
| CoW String (cycle 1) | 7.67/8 avg | 7.00/8 avg | Empty string guard |
| CoW String (cycle 2) | 8.00/8 avg | 8.00/8 avg | Ceiling effect |
| SSO String | **0/10 avg** | **7.67/10 avg** | Declaration order workflow |
