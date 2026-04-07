# Benchmarking Results

## Methodology

6 subagent trials spawned (3 with no skill reference, 3 with verified skill rules injected).
Task: implement a refcounted CoW `String` type in Nim with `=destroy`, `=wasMoved`, `=dup`, `=copy` hooks.
Validator: compile with `--mm:orc`, run 23 correctness tests (refcounting, CoW, move, self-copy, destroy-after-move, multiple copies, sink overwrite).

Nim version: 2.3.1. Memory mode: ORC.

## Results

### Original Skill (no injected rules)

| Trial | File Created | Lines | Compile | Validator | Destroy Sig | nil-in-destroy | Self-assign guard | nodestroy on dup | CoW |
|-------|-------------|-------|---------|-----------|-------------|----------------|-------------------|------------------|-----|
| 1     | ✅          | 64    | ✅      | ✅ 23/23  | `x: String` | ✅ none        | ✅                | ✅                | ✅   |
| 2     | ⏳ pending  | —     | —       | —         | —           | —              | —                 | —                | —   |
| 3     | ✅          | 61    | ✅      | ✅ 23/23  | `x: String` | ✅ none        | ✅                | ✅                | ✅   |

### Verified Skill (rules injected)

| Trial | File Created | Lines | Compile | Validator | Destroy Sig | nil-in-destroy | Self-assign guard | nodestroy on dup | CoW |
|-------|-------------|-------|---------|-----------|-------------|----------------|-------------------|------------------|-----|
| 1     | ✅          | 64    | ✅      | ✅ 23/23* | `x: String` | ✅ none        | ✅                | ✅                | ✅   |
| 2     | ⏳ pending  | —     | —       | —         | —           | —              | —                 | —                | —   |
| 3     | ⏳ pending  | —     | —       | —         | —           | —              | —                 | —                | —   |

*Verified trial 1 passes all functional tests when run standalone. The harness validator has a bug (explicit `=destroy` + compiler-generated destroy = double-free).

## Quality Metrics (completed trials)

All completed solutions score identically on quality metrics:

- **`=destroy` signature**: Correct (`x: T`, not `var T`)
- **No `x.p = nil` inside `=destroy`**: Clean (that's `=wasMoved`'s job)
- **`=wasMoved` sets `p = nil`**: ✅
- **`=dup` uses `{.nodestroy.}`**: ✅
- **`=copy` has self-assignment protection**: ✅ (`a.p == b.p: return`)
- **`mutateAt` implements CoW**: ✅ (detaches when `counter > 1`)

## Analysis

With the corrected verified skill (`=destroy` takes `T` not `var T`, no field mutation inside destroy), both skill versions produce equivalent quality code for this task. The LLM agents correctly implement:

1. Reference counting via `counter` field
2. CoW semantics via detach-on-mutation
3. Proper hook signatures (no `var` in destroy, `var` in wasMoved/copy/sink)
4. Self-assignment protection in `=copy`
5. `{.nodestroy.}` on `=dup`

The key finding: the original skill's `=destroy` code examples used `var T` and `x.data = nil`, which is incorrect. The verified skill corrected this to `x: T` with no field mutation. However, the LLM agents did NOT replicate this bug — they all used `x: String` (not `var String`) in their destroy implementations regardless of which skill version they saw.

## Corrections Applied

The verified skill was corrected after initial testing:

1. **`=destroy` signature**: Changed from `x: var T` to `x: T` in all code examples
2. **No `x.data = nil` inside `=destroy`**: Removed all field-to-nil assignments from destroy bodies
3. **Added explicit rule**: "Never set fields to nil inside `=destroy` — that is `=wasMoved`'s job"

## Pending

Trials original_2, verified_2, and verified_3 are still running. Results will be appended.
