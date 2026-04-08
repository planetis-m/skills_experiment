# Benchmark Results — nim-api-design v2 (Unblinded)

## Hidden Mapping
- **Verified skill** → runs 02, 04, 05
- **Original skill** → runs 01, 03, 06

## Rubric (14 items)

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
| 3. distinct+ borrow | ✓ | ✓ | ✓ |
| 4. Constructors | ✓ | ✓ | ✓ |
| 5. No 2nd repr | ✓ | ✓ | ✓ |
| 6. Named objects | ✓ | ✓ | ✓ |
| 7. Read surface | ✓ | ✓ | ✓ |
| 8. One var tags | ✓ | ✓ | ✓ |
| 9. No scalar var | ✓ | ✓ | ✓ |
| 10. Role map | ✓ | ✓ | ✓ |
| 11. Private helper | ✗ exported | ✗ exported | ✗ exported |
| 12. No silent defaults | ✓ | ✓ | ✓ |
| 13. No temp locals | ✓ | ✓ | ✓ |
| 14. Descriptive names | ✓ | ✓ | ✓ |
| **Total** | **13/14** | **13/14** | **13/14** |

**Verified avg: 13.0/14**

### Original skill (runs 01, 03, 06)

| Item | run_01 | run_03 | run_06 |
|------|--------|--------|--------|
| 1. Compiles/runs | ✓ | ✓ | ✓ |
| 2. SMOKE: PASS | ✓ | ✓ | ✓ |
| 3. distinct+ borrow | ✓ | ✓ | ✓ |
| 4. Constructors | ✓ | ✓ | ✓ |
| 5. No 2nd repr | ✓ | ✓ | ✓ |
| 6. Named objects | ✓ | ✓ | ✓ |
| 7. Read surface | ✓ | ✓ | ✓ |
| 8. One var tags | ✓ | ✓ | ✓ |
| 9. No scalar var | ✓ | ✓ | ✓ |
| 10. Role map | ✓ | ✓ | ✓ |
| 11. Private helper | ✗ exported | ✗ exported | ✗ exported |
| 12. No silent defaults | ✓ | ✓ | ✓ |
| 13. No temp locals | ✓ | ✓ | ✓ |
| 14. Descriptive names | ✓ | ✓ | ✓ |
| **Total** | **13/14** | **13/14** | **13/14** |

**Original avg: 13.0/14**

## Summary

Both groups scored identically: **13.0/14 average**. The only failure in every single trial was
rubric item 11: the error helper proc was exported (`*`) instead of kept private. This happened
in all 6 runs regardless of which skill was used.

The updated task (flexible proc names, API role map) gave more room for the skills to influence
design decisions, but both skills produced structurally equivalent solutions. All solutions:
- Used `Table[PackageId, PackageMeta]` for internal storage
- Named the insert-or-replace proc `put`
- Named the mutable tag accessor `mtags` or `mtagsOf`
- Exported the error helper (the universal failure)

### Failure mode analysis
The error helper export issue is likely driven by the task spec's wording: "one shared private helper
marked `{.noinline, noreturn.}`" — workers may overlook "private" and focus on the pragma. Both skills
correctly advise keeping error helpers private, so this appears to be a task-compliance issue rather
than a skill guidance issue.

### Conclusion
No meaningful difference between original and verified skill on this benchmark. The task,
while more open-ended than v1, still specified behavior tightly enough that both skills
produced equivalent results. The universal failure (exported helper) is a task-reading issue
rather than a skill gap.
