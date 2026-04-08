---
name: nim-ownership-hooks
description: Design, review, and implement Nim ARC/ORC ownership hooks and move semantics. Empirically verified against Nim 2.3.1 / ORC.
---

# Nim Ownership Hooks

## 1. Preamble

Use this skill when editing or reviewing Nim ownership hooks under ARC/ORC (`--mm:arc` or `--mm:orc`). Start by classifying the type's ownership model, then implement only the hook set that model needs.

Extended examples for each ownership model live in `references/`.

## 2. Rules

**Do not write hooks unless the type owns a resource the compiler cannot release.** The compiler auto-manages `string`, `seq[T]`, `ref T`, `array`, tuples, closures, and objects whose fields are all auto-managed. Hooks lift through nesting — if a field has custom hooks, the enclosing type gets correct auto-generated hooks for free.

Custom hooks are needed only for: raw pointers (`ptr T`) to manually allocated memory, OS file descriptors, distinct-type handles, or any non-managed resource.

### Hook signatures

| Hook | Signature | Key rule |
|------|-----------|----------|
| `=destroy` | `proc \`=destroy\`*(x: T)` | **Use `T`, not `var T`.** Check sentinel (`nil`) before accessing fields. |
| `=wasMoved` | `proc \`=wasMoved\`*(x: var T)` | Sets fields to default state. The compiler then eliminates the subsequent destroy call entirely. |
| `=sink` | `proc \`=sink\`*(dest: var T; src: T)` | Destroy dest, transfer fields. No self-assignment check needed. |
| `=copy` | `proc \`=copy\`*(dest: var T; src: T)` | Deep-copy types: must have self-assignment protection. Refcounted types: optional (counter balances). Move-only: use bare `{.error.}`. |
| `=dup` | `proc \`=dup\`*(src: T): T` | Deep-copy containers: use `{.nodestroy.}`. Refcounted types: optional. |
| `=trace` | `proc \`=trace\`*(x: var T; env: pointer)` | Only for ORC + manually allocated containers with ref-type elements. Forward-declare alongside `=destroy`. |

### Declaration order

Declare hooks **before** any proc that mentions the type — including `=dup`, whose body can trigger implicit `=copy` generation. Safe order:

```
type T = object ...
proc `=destroy`*(x: T) = ...
proc `=wasMoved`*(x: var T) = ...
proc `=copy`*(dest: var T; src: T) = ...
proc `=dup`*(src: T): T = ...     # after =copy to avoid conflicts
```

Templates are safe between type and hooks. Generics used before their hooks trigger compiler errors.

### Move semantics

- `move(x)` forces move. Source left in moved-from state.
- `ensureMove(x)` is a compile-time annotation for rvalues and sink params. Fails for lvalues with destructors.
- `sink` parameters are **affine**: callee may or may not consume.
- Object and tuple fields are separate entities for sink last-use analysis.
- Compiler inserts `=copy`/`=dup` when sink argument is not last use.
- Compiler synthesizes `=sink` from `=destroy` + `copyMem` when no custom `=sink` provided.

### Edge cases

- **Zero-length allocations**: Guard against `alloc(0)` in constructors and `=copy`. Only allocate when length is positive.
- **Refcounter conventions**: Standard (counter=1 exclusive, frees at 0) or inverted (counter=0 exclusive, frees at 0). Both valid.
- **Thread safety**: Use `allocShared`/`deallocShared` with `when compileOption("threads")`.

## 3. Workflow

### Step 1: Classify the ownership model

| Model | Hooks needed |
|-------|-------------|
| Plain / auto-managed | None |
| Borrowing / view | None. Use `lent T` for accessors. |
| Move-only owner | `=destroy`, `=wasMoved`, `=copy` as `{.error.}` |
| Deep-owning container | `=destroy`, `=wasMoved`, `=copy`, `=dup` |
| Shared / refcounted | `=destroy`, `=wasMoved`, `=dup`, `=copy` |

### Step 2: Implement the minimal hook set

For each model, see `references/` for complete examples. Inline example — refcounted handle:

```nim
proc `=destroy`*(x: Handle) =
  if x.p != nil:
    dec x.p.counter
    if x.p.counter == 0:
      dealloc(x.p)

proc `=wasMoved`*(x: var Handle) =
  x.p = nil

proc `=dup`*(b: Handle): Handle {.nodestroy.} =
  result.p = b.p
  if b.p != nil: inc b.p.counter

proc `=copy`*(a: var Handle; b: Handle) =
  if a.p == b.p: return
  `=destroy`(a)
  `=wasMoved`(a)
  a.p = b.p
  if b.p != nil: inc b.p.counter
```

### Step 3: Verify with `--expandArc`

```bash
nim c --mm:orc --expandArc:nameOfFunction yourfile.nim
```

Shows every hook the compiler inserts. Confirm synthesized hooks match intent.

### Step 4: Run stress tests

Test: move, overwrite, copy independence, dup independence, destroy-after-move, self-copy, sink from temporaries, zero-length initialization.

## Common mistakes

| Mistake | Why wrong |
|---------|-----------|
| `=destroy` with `var T` | Both compile, but `T` prevents accidental field mutation. |
| Setting fields to nil inside `=destroy` | Use `=wasMoved` for that. |
| Declaring `=dup` before `=copy` | `=dup` body can trigger implicit `=copy` → conflict. |
| Missing self-assignment guard in deep-copy `=copy` | Destroys source before reading. |
| Self-assignment check in `=sink` | Compiler eliminates simple self-assignments. |
| Missing `{.nodestroy.}` on deep-copy `=dup` | Compiler destroys result before return. |
| Custom `=sink` when synthesized is fine | Unnecessary complexity. |
| `copyMem` in `=sink` bypassing child hooks | Breaks ownership chain. |
| Missing zero-length guard | `alloc(0)` + indexing crashes. |
| `ensureMove` on lvalue with destructor | Compile error. |
| `alloc` in multi-threaded code | Must use `allocShared`/`deallocShared`. |

## References

- `references/move_only_owner.md` — exclusive resource ownership
- `references/deep_owning_container.md` — manual allocation with deep copy
- `references/shared_refcounted.md` — refcounted handle (standard + inverted counter)
- `references/cow_string.md` — copy-on-write string (adapted from Nim stdlib)
- `references/custom_sink.md` — when and how to write a custom `=sink`

## Changelog
- 2026-04-07: Initial version
- 2026-04-07: Added zero-length guards, non-var destroy preference
- 2026-04-07: Added refcounted nuances from cowstrings analysis
- 2026-04-08: Restructured — examples moved to references/, workflow-focused SKILL.md
