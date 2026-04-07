---
name: nim-ownership-hooks
description: Design, review, and implement Nim ARC/ORC ownership hooks and move semantics. Empirically verified against Nim 2.3.1 / ORC.
---

# Nim Ownership Hooks — Verified Skill

## 1. Preamble

Use this skill when editing or reviewing Nim ownership hooks under ARC/ORC (`--mm:arc` or `--mm:orc`). Start by classifying the type's ownership model, then implement only the hook set that model needs.

## 2. Verified Stance

**Do not write hooks unless the type owns a resource the compiler cannot release.** The compiler auto-manages `string`, `seq[T]`, `ref T`, `array`, tuples, closures, and objects whose fields are all auto-managed. Hooks lift through nesting — if a field has custom hooks, the enclosing type gets correct auto-generated hooks for free.

Custom hooks are needed only for: raw pointers (`ptr T`) to manually allocated memory, OS file descriptors, distinct-type handles, or any non-managed resource.

### Hook signatures

| Hook | Signature | Key rule |
|------|-----------|----------|
| `=destroy` | `proc \`=destroy\`*(x: T)` | **Use `T`, not `var T`.** The non-var form prevents accidental field mutation inside the destructor. Check sentinel (`nil`) before freeing. |
| `=wasMoved` | `proc \`=wasMoved\`*(x: var T)` | Sets fields to default state so destroy is no-op. After wasMoved, the compiler eliminates the subsequent destroy call entirely. |
| `=sink` | `proc \`=sink\`*(dest: var T; src: T)` | Destroy dest, transfer fields. No self-assignment check needed. |
| `=copy` | `proc \`=copy\`*(dest: var T; src: T)` | **Must** have self-assignment protection. After destroy+wasMoved on dest, check `src.data != nil` before allocating. For move-only types, use bare `{.error.}`. |
| `=dup` | `proc \`=dup\`*(src: T): T {.nodestroy.}` | Optimized duplication. Share for refcounted types, deep-copy for containers. `{.nodestroy.}` inhibits all compiler hook insertions. |
| `=trace` | `proc \`=trace\`*(x: var T; env: pointer)` | Only for ORC + manually allocated containers with ref-type elements. Forward-declare alongside `=destroy` to avoid mutual-use conflicts. |

### Move semantics

- `move(x)` forces move. Source left in moved-from state.
- `ensureMove(x)` is a compile-time annotation. Works for rvalues and sink params. Fails for lvalues with destructors.
- `sink` parameters are **affine**: callee may or may not consume.
- Object and tuple fields are treated as separate entities for sink last-use analysis — consuming `tup[0]` leaves `tup[1]` alive.
- Compiler inserts `=copy`/`=dup` when sink argument is not last use.
- Compiler synthesizes `=sink` from `=destroy` + `copyMem` when no custom `=sink` provided.

### Declaration order

Declare hooks before procs that use the type. Generics used before their hooks trigger compiler errors. Templates are safe between type and hooks.

### Edge case: zero-length allocations

When implementing constructors or copy operations that allocate backing storage:
- **Guard against zero-length inputs.** `alloc(0)` may return nil or an invalid pointer.
- In `=copy`, after destroying dest and calling `=wasMoved`, check `src.data != nil and src.len > 0` before allocating and copying.
- In `initXxx` constructors, only allocate when the input length is positive.

## 3. Deterministic Workflow

### Step 1: Classify the ownership model

| Model | Hooks needed |
|-------|-------------|
| Plain / auto-managed | None |
| Borrowing / view | None. Use `lent T` for accessors. |
| Move-only owner | `=destroy`, `=wasMoved`, `=copy` as `{.error.}` |
| Deep-owning container | `=destroy`, `=wasMoved`, `=copy`, `=dup` |
| Shared / refcounted | `=destroy`, `=wasMoved`, `=dup`, `=copy` (share, inc counter) |

### Step 2: Declare hooks before use

```nim
type T = object ...
# templates OK here
proc `=destroy`*(x: T) = ...
proc `=wasMoved`*(x: var T) = ...
proc `=copy`*(dest: var T; src: T) = ...
# other procs after hooks
```

### Step 3: Implement hooks per model

**Move-only owner:**
```nim
proc `=destroy`*(x: T) =
  if x.data != nil:
    dealloc(x.data)

proc `=wasMoved`*(x: var T) =
  x.data = nil

proc `=copy`*(dest: var T; src: T) {.error.}
```

**Deep-owning container (with zero-length guard):**
```nim
proc `=destroy`*(x: Container) =
  if x.data != nil:
    dealloc(x.data)

proc `=wasMoved`*(x: var Container) =
  x.data = nil
  x.len = 0

proc `=dup`*(src: Container): Container {.nodestroy.} =
  result = Container(len: src.len, data: nil)
  if src.data != nil and src.len > 0:
    result.data = cast[ptr Elem](alloc(src.len * sizeof(Elem)))
    copyMem(result.data, src.data, src.len * sizeof(Elem))

proc `=copy`*(dest: var Container; src: Container) =
  if dest.data == src.data: return
  `=destroy`(dest)
  `=wasMoved`(dest)
  dest.len = src.len
  if src.data != nil and src.len > 0:
    dest.data = cast[ptr Elem](alloc(src.len * sizeof(Elem)))
    copyMem(dest.data, src.data, src.len * sizeof(Elem))
```

**Shared/refcounted handle:**
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

**Custom `=sink` (only when needed):**
```nim
proc `=sink`*(dest: var T; src: T) =
  `=destroy`(dest)
  `=wasMoved`(dest)  # needed when not all fields overwritten
  dest.field = src.field
```

**Constructor with zero-length guard:**
```nim
proc initContainer(items: openArray[Elem]): Container =
  result = Container(len: items.len, data: nil)
  if items.len > 0:
    result.data = cast[ptr Elem](alloc(items.len * sizeof(Elem)))
    for i in 0..<items.len:
      (cast[ptr UncheckedArray[Elem]](result.data))[i] = items[i]
```

### Step 4: Verify with `--expandArc`

```bash
nim c --mm:orc --expandArc:nameOfFunction yourfile.nim
```

Shows every hook the compiler inserts. Confirm synthesized hooks match intent.

### Step 5: Run stress tests

Compile with `--mm:orc` and test: move, overwrite, copy independence, dup independence, destroy-after-move, self-copy, sink from temporaries, **zero-length initialization**, **copy of empty into non-empty**, **copy of non-empty into empty**.

## Common mistakes

| Mistake | Why wrong |
|---------|-----------|
| Setting fields to nil inside `=destroy` | Use `=wasMoved` for that. `=destroy` takes `T` (non-var), so you can't mutate fields anyway. |
| `=destroy` with `var T` | Both compile, but `T` is the preferred form — it prevents accidental field mutation. |
| Missing zero-length guard in constructors | `alloc(0)` + indexing crashes. Guard with `if len > 0`. |
| Missing nil guard in `=copy` after destroy | After `=wasMoved(dest)`, check `src.data != nil` before allocating. |
| Self-assignment check in `=sink` | Compiler eliminates simple self-assignments. |
| Missing self-assignment guard in `=copy` | Destroys source before reading. |
| Custom `=sink` when synthesized is fine | Unnecessary complexity. |
| `copyMem` in `=sink` bypassing child hooks | Breaks ownership chain. |
| `ensureMove` on lvalue with destructor | Compile error — destruction counts as use. |
| Hooks declared after generic usage | Triggers phase-order error. |

## Changelog
- 2026-04-07: Initial verified version
- 2026-04-07: Added zero-length allocation guidance, strengthened =destroy to prefer non-var form
