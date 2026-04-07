---
name: nim-ownership-hooks
description: Design, review, and implement Nim ARC/ORC ownership hooks and move semantics. Empirically verified against Nim 2.3.1 / ORC (35 claims, 31 tested, 31 passed).
---

# Nim Ownership Hooks — Verified Skill

## 1. Preamble

Use this skill when editing or reviewing Nim ownership hooks under ARC/ORC (`--mm:arc` or `--mm:orc`). Start by classifying the type's ownership model, then implement only the hook set that model needs.

Verified against Nim 2.3.1 with `--mm:orc`. 35 claims extracted, 31 tested, 31 passed, 2 refinement cycles.

## 2. Verified Stance

**Do not write hooks unless the type owns a resource the compiler cannot release.** The compiler auto-manages `string`, `seq[T]`, `ref T`, `array`, tuples, closures, and objects whose fields are all auto-managed (C01). Hooks lift through nesting — if a field has custom hooks, the enclosing type gets correct auto-generated hooks (C02).

Custom hooks are needed only for: raw pointers (`ptr T`) to manually allocated memory, OS file descriptors, distinct-type handles (C03).

### Hook signatures

| Hook | Signature | Key rule |
|------|-----------|----------|
| `=destroy` | `proc \`=destroy\`*(x: T)` | **Use `T`, not `var T`.** The non-var form prevents accidental field mutation inside the destructor. Check sentinel (`nil`) before freeing (C06, C34). |
| `=wasMoved` | `proc \`=wasMoved\`*(x: var T)` | Sets fields to default state so destroy is no-op (C07). After wasMoved, compiler eliminates the subsequent destroy call entirely (C22). |
| `=sink` | `proc \`=sink\`*(dest: var T; src: T)` | Destroy dest, transfer fields. No self-assignment check needed (C09). |
| `=copy` | `proc \`=copy\`*(dest: var T; src: T)` | **Must** have self-assignment protection (C10). After destroy+wasMoved on dest, check `src.data != nil` before allocating (C35). For move-only types, use bare `{.error.}` (C11). |
| `=dup` | `proc \`=dup\`*(src: T): T {.nodestroy.}` | Optimized duplication. Share for refcounted types, deep-copy for containers (C12). `{.nodestroy.}` inhibits all compiler hook insertions (C26). |
| `=trace` | `proc \`=trace\`*(x: var T; env: pointer)` | Only for ORC + manually allocated containers with ref-type elements (C05). Forward-declare alongside `=destroy` to avoid mutual-use conflicts (C30). |

### Move semantics

- `move(x)` forces move. Source left in moved-from state (C19).
- `ensureMove(x)` is a compile-time annotation. Works for rvalues and sink params. Fails for lvalues with destructors (C20).
- `sink` parameters are **affine**: callee may or may not consume (C14).
- Object and tuple fields are treated as separate entities for sink last-use analysis — consuming `tup[0]` leaves `tup[1]` alive (C28).
- Compiler inserts `=copy`/`=dup` when sink argument is not last use (C15).
- Compiler synthesizes `=sink` from `=destroy` + `copyMem` when no custom `=sink` provided (C08).

### Declaration order

Declare hooks before procs that use the type. Generics used before their hooks trigger compiler errors (C16). Templates are safe between type and hooks (C18).

### Edge case: zero-length allocations

When implementing constructors or copy operations that allocate backing storage:
- **Guard against zero-length inputs** (C33). `alloc(0)` may return nil or an invalid pointer.
- In `=copy`, after destroying dest and calling `=wasMoved`, check `src.data != nil and src.len > 0` before allocating and copying (C35).
- In `initXxx` constructors, only allocate when the input length is positive.

## 3. Deterministic Workflow

### Step 1: Classify the ownership model

| Model | Hooks needed |
|-------|-------------|
| Plain / auto-managed | None |
| Borrowing / view | None. Use `lent T` for accessors (C13). |
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

## 4. Empirical Evidence

35 claims tested against Nim 2.3.1 / `--mm:orc` across 2 refinement cycles:

| Test | Claims | Result |
|------|--------|--------|
| test_c01_auto_managed.nim | C01 | ✅ Auto-managed types need no hooks |
| test_c02_hook_lifting.nim | C02 | ✅ Hooks lift through nesting |
| test_c03_raw_pointer.nim | C03, C31 | ✅ Raw pointers need custom destroy |
| test_c04_export_hooks.nim | C04 | ✅ Exported hooks work |
| test_c05_trace.nim | C05 | ✅ =trace compiles under ORC |
| test_c06_c07_sentinel.nim | C06, C07 | ✅ Sentinel + wasMoved prevent double-free |
| test_c08_synthesized_sink.nim | C08 | ✅ Synthesized =sink correct |
| test_c09_c10_self_assign.nim | C09, C10 | ✅ Self-sink eliminated; self-copy needs guard |
| test_c11_error_copy.nim | C11 | ✅ {.error.} blocks copy |
| test_c12_dup.nim | C12 | ✅ =dup{.nodestroy.} creates independent copy |
| test_c13_lent.nim | C13 | ✅ lent T borrows |
| test_c14_sink_affine.nim | C14 | ✅ Sink params are affine |
| test_c15_sink_duplicate.nim | C15 | ✅ Compiler copies for non-last-use |
| test_c16_order_bad_generic.nim | C16 | ✅ Generic before hooks = compile error |
| test_c18_template_between.nim | C18 | ✅ Templates safe between type and hooks |
| test_c19_move.nim | C19 | ✅ move() forces move |
| test_c20_ensuremove.nim | C20 | ✅ ensureMove works for rvalues |
| test_c21_destroy_nonvar.nim | C21 | ✅ =destroy(x: T) compiles, no field mutation |
| test_c22_wasMoved_destroy_cancel.nim | C22 | ✅ Compiler eliminates destroy after wasMoved |
| test_c23_destroy_no_raise.nim | C23 | ✅ =destroy implicitly non-raising |
| test_c26_nodestroy.nim | C26 | ✅ {.nodestroy.} inhibits all hook calls |
| test_c28_field_sink.nim | C28 | ✅ Tuple field independence for sink analysis |
| test_c30_trace_mutual.nim | C30 | ✅ Forward declarations prevent trace/destroy conflict |
| test_c33_zero_length_guard.nim | C33 | ✅ Zero-length guard prevents crashes |
| test_c34_destroy_prefer_nonvar.nim | C34 | ✅ Both T and var T compile; T prevents mutation |
| test_c35_copy_nil_guard.nim | C35 | ✅ Nil guard in copy handles empty transitions |

## Common mistakes

| Mistake | Why wrong |
|---------|-----------|
| Setting fields to nil inside `=destroy` | Use `=wasMoved` for that. `=destroy` takes `T` (non-var), so you can't mutate fields anyway (C34). |
| `=destroy` with `var T` | Both compile, but `T` is the preferred form. It prevents accidental field mutation (C34). |
| Missing zero-length guard in constructors | `alloc(0)` + indexing crashes. Guard with `if len > 0` (C33). |
| Missing nil guard in `=copy` after destroy | After `=wasMoved(dest)`, check `src.data != nil` before allocating (C35). |
| Self-assignment check in `=sink` | Compiler eliminates simple self-assignments (C09). |
| Missing self-assignment guard in `=copy` | Destroys source before reading (C10). |
| Custom `=sink` when synthesized is fine | Unnecessary complexity (C08). |
| `copyMem` in `=sink` bypassing child hooks | Breaks ownership chain. |
| `ensureMove` on lvalue with destructor | Compile error — destruction counts as use (C20). |
| Hooks declared after generic usage | Triggers phase-order error (C16). |

## Changelog
- 2026-04-07: Initial verified version (25 claims)
- 2026-04-07: Refinement cycle 2 — added C33-C35 from benchmark failures, tested C22/C23/C26/C28/C30, updated =destroy guidance to prefer non-var form, added zero-length allocation guidance
