# Benchmark Results — nim-api-design v3 (Unblinded)

## Hidden Mapping
- **Verified skill** → runs 02, 04, 05
- **Original skill** → runs 01, 03, 06

## Rubric (14 items, binary pass/fail)

1. Compiles and runs with `nim c -r --mm:orc`
2. Runtime prints `SMOKE: PASS`
3. `PackageId` is `distinct string` with borrowed `==` and `$`
4. Public API exposes one empty constructor and one conversion constructor
5. No second public catalog representation
6. Public semantic data uses named objects, not status tuples
7. Read surface includes full-metadata accessor and scalar read access
8. Exactly one public mutable accessor exposes the stored tag sequence
9. No scalar `var` accessor exposed
10. API role map present and matches exported procs
11. Missing-package failures through one shared **private** `{.noinline, noreturn.}` helper
12. Missing data not reported via silent defaults
13. Accessor code does not use temp locals that create escaping-borrow issues
14. Public names are descriptive rather than generic

## Scores

### Verified skill (runs 02, 04, 05)

| Item | run_02 | run_04 | run_05 |
|------|--------|--------|--------|
| 1. Compiles/runs | ✓ | ✓ | ✓ |
| 2. SMOKE: PASS | ✓ | ✓ | ✓ |
| 3. distinct + borrow | ✓ | ✓ | ✓ |
| 4. Constructors | ✓ | ✓ | ✓ |
| 5. No 2nd repr | ✓ | ✓ | ✓ |
| 6. Named objects | ✓ | ✓ | ✓ |
| 7. Read surface | ✓ | ✓ | ✓ |
| 8. One var tags | ✓ | ✓ | ✓ |
| 9. No scalar var | ✓ | ✓ | ✓ |
| 10. Role map | ✓ | ✓ | ✓ |
| 11. Private helper | ✓ | ✓ | ✓ |
| 12. No silent defaults | ✓ | ✓ | ✓ |
| 13. No escaping-borrow temps | ✓ | ✓ | ✓ |
| 14. Descriptive names | ✓ | ✓ | ✓ |
| **Total** | **14/14** | **14/14** | **14/14** |

**Verified avg: 14.0/14**

### Original skill (runs 01, 03, 06)

| Item | run_01 | run_03 | run_06 |
|------|--------|--------|--------|
| 1. Compiles/runs | ✓ | ✓ | ✓ |
| 2. SMOKE: PASS | ✓ | ✓ | ✓ |
| 3. distinct + borrow | ✓ | ✓ | ✓ |
| 4. Constructors | ✓ | ✓ | ✓ |
| 5. No 2nd repr | ✓ | ✓ | ✓ |
| 6. Named objects | ✓ | ✓ | ✓ |
| 7. Read surface | ✓ | ✓ | ✓ |
| 8. One var tags | ✓ | ✓ | ✓ |
| 9. No scalar var | ✓ | ✓ | ✓ |
| 10. Role map | ✓ | ✓ | ✓ |
| 11. Private helper | ✓ | ✓ | ✓ |
| 12. No silent defaults | ✓ | ✓ | ✓ |
| 13. No escaping-borrow temps | ✓ | ✓ | ✓ |
| 14. Descriptive names | ✓ | ✓ | ✓ |
| **Total** | **14/14** | **14/14** | **14/14** |

**Original avg: 14.0/14**

## Summary

Both groups scored perfectly: **14.0/14 average**. Every trial passed every rubric item.

Compared to v2 (where the universal failure was exporting the error helper), this time all 6 runs
kept the helper private. The task spec was the same, but the workers were more careful this run.

### Design observations
- All runs used `distinct string` + `{.borrow.}` correctly
- All used named objects (no status tuples)
- All kept error helpers private with `{.noinline, noreturn.}`
- All provided exactly one mutable tag accessor, no scalar var accessors
- Run_05 (verified) added `{.raises: [KeyError].}` annotations — the only run to do so, likely
  influenced by the verified skill's emphasis on exception surface documentation
- Run_03 (original) returned `PackageMeta` by value (not lent) in its `meta` accessor —
  functionally correct but less idiomatic

### Conclusion
Both skills produce equivalent, correct results. The task is well-specified enough that even
without a skill, a competent coder would produce the right API. The verified skill's only
observable influence was run_05's `{.raises:}` annotation — a subtle but real improvement.
