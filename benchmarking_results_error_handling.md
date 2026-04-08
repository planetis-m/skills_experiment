# Benchmark Results: nim-error-handling

## Task
Implement a document conversion pipeline with proper error handling:
- `loadDocument` — raises IOError on empty path
- `renderPage` — raises ValueError on OOB, IOError on empty output
- `convertDocument` — chains steps, no catching
- `runBatch` — boundary catch with CatchableError
- `tryParseInt` — bool-return parse helper
- `translateError` — catch OSError, re-raise as IOError with context

## Groups
- **A-group (A1-A3)**: Original human-written skill
- **B-group (B1-B3)**: Refined skill

## Results

### Compile & Validator
| Trial | Compiles | Validator | Group |
|-------|----------|-----------|-------|
| A1 | ✅ | ✅ ALL TESTS PASSED | Original |
| A2 | ✅ | ✅ ALL TESTS PASSED | Original |
| A3 | ✅ | ✅ ALL TESTS PASSED | Original |
| B1 | ✅ | ✅ ALL TESTS PASSED | Refined |
| B2 | ✅ | ❌ success result carried no payload data | Refined |
| B3 | ✅ | ✅ ALL TESTS PASSED | Refined |

### Skill compliance
| Check | A1 | A2 | A3 | B1 | B2 | B3 |
|-------|----|----|----|----|----|----|
| CatchableError (not Exception) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| No empty except blocks | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| convertDocument has no catch | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| loadDocument has no catch | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| No custom exception types | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| runBatch success carries data | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |

## Analysis

The benchmark is still fairly easy, but the stricter validator now catches one real gap: `eh_B2` reports success without returning any payload bytes on the success path.

The original skill already provides strong guidance for this domain. The refined skill is clearer procedurally, but this benchmark still does not separate the two versions reliably because most implementations converge on the same obvious structure.

**Why this benchmark cannot differentiate well:**
1. The skill's rules are prescriptive and easy to follow (catch only at boundaries, use CatchableError, don't swallow)
2. Unlike ownership hooks (where declaration order causes compile-die failures), error handling mistakes tend to be logic bugs caught by the validator, not structural compile errors
3. The current task focuses on one straightforward boundary-propagation pattern
4. The one observed failure is an incomplete success-path implementation, not a broader misunderstanding of the domain

**Conclusion:** The cleaned task and validator are better than the previous harness because they now check both failure and success behavior at the batch boundary. Even so, this benchmark remains closer to a smoke test than a strong discriminator. Future benchmarking would need harder tasks such as async error handling, nested translation chains, or recovery logic.
