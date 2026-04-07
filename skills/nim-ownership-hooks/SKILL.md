---
name: nim-ownership-hooks
description: Design, review, and implement Nim ARC/ORC ownership hooks and move semantics for value types, containers, shared handles, and manually allocated storage. Empirically verified against Nim 2.3.1 / ORC. Cross-referenced with official Nim "Destructors and Move Semantics" documentation.
---

# Nim Ownership Hooks and Move Semantics

Verified on Nim 2.3.1 with `--mm:orc`.

Use this skill when editing or reviewing Nim ownership hooks under ARC/ORC (`--mm:arc` or `--mm:orc`).
Start by classifying the type's ownership model, then implement only the hook set that model needs.

## When to write custom hooks

Most types do **not** need custom hooks. The compiler auto-manages destruction for primitives, `string`, `seq[T]`, `ref T`, `array`, tuples, closures, and objects whose fields are all auto-managed.

Write custom hooks only when the type holds a resource the compiler cannot release on its own:

- Raw pointers (`ptr T`) to manually allocated memory
- OS file descriptors or socket handles
- Distinct types used as handles
- Any other non-managed resource

If in doubt, do not write hooks.

## Ownership models and their hook sets

### Plain value / compiler-managed aggregate

No custom hooks. The compiler recursively generates correct hooks through all fields.

### Borrowing / view type

No custom hooks. Use `lent T` for immutable accessors:

```nim
proc `[]`(x: MyContainer; i: int): lent Elem =
  x.data[i]
```

`lent T` is a hidden pointer, like `var T` but immutable. No destructor is injected for `lent T` or `var T` expressions.

### Move-only owner

For exclusive resources (manually allocated buffers, single-owner handles):

```nim
proc `=destroy`*(x: T) =
  if x.data != nil:
    dealloc(x.data)

proc `=wasMoved`*(x: var T) =
  x.data = nil

proc `=copy`*(dest: var T; src: T) {.error.}
```

### Deep-owning container

For containers that manually allocate backing storage and own their elements:

```nim
proc `=destroy`*(x: T) =
  if x.data != nil:
    for i in 0..<x.len:
      `=destroy`(x.data[i])
    dealloc(x.data)

proc `=wasMoved`*(x: var T) =
  x.data = nil

proc `=copy`*(dest: var T; src: T) =
  if dest.data == src.data: return    # self-assignment protection
  `=destroy`(dest)
  `=wasMoved`(dest)
  dest.len = src.len
  dest.cap = src.cap
  if src.data != nil:
    dest.data = cast[typeof(dest.data)](alloc(dest.cap * sizeof(Elem)))
    for i in 0..<dest.len:
      dest.data[i] = src.data[i]

proc `=dup`*(src: T): T {.nodestroy.} =
  result = T(len: src.len, cap: src.cap, data: nil)
  if src.data != nil:
    result.data = cast[typeof(result.data)](alloc(result.cap * sizeof(Elem)))
    for i in 0..<result.len:
      result.data[i] = `=dup`(src.data[i])
```

### Shared / refcounted handle

`=copy` and `=dup` share the payload (increment counter), they do NOT deep-copy:

```nim
proc `=destroy`*(x: T) =
  if x.p != nil:
    dec x.p.counter
    if x.p.counter == 0:
      dealloc(x.p)

proc `=wasMoved`*(x: var T) =
  x.p = nil

proc `=dup`*(b: T): T {.nodestroy.} =
  result.p = b.p
  result.len = b.len
  if b.p != nil:
    inc b.p.counter

proc `=copy`*(a: var T; b: T) =
  if a.p == b.p: return
  `=destroy`(a)
  `=wasMoved`(a)
  a.p = b.p
  a.len = b.len
  if b.p != nil:
    inc b.p.counter
```

Do not force one ownership model onto another.

## Hook implementations

### `=destroy`

```nim
proc `=destroy`*(x: T) =
  if x.field != nil:
    freeResource(x.field)
```

**Rules:**
- Takes `T` (not `var T`). You cannot assign to fields inside destroy.
- Implicitly annotated `.raises: []`. A destructor should not raise exceptions.
- Check the moved-from sentinel (usually `nil`) before freeing.
- **Never set fields to nil inside `=destroy`** — that is `=wasMoved`'s job.
- Destroy nested values before freeing raw storage.

### `=wasMoved`

```nim
proc `=wasMoved`*(x: var T) =
  x.field = nil
```

Sets the object to its default state so `=destroy` becomes a no-op.

### `=sink`

```nim
proc `=sink`*(dest: var T; src: T) =
  `=destroy`(dest)
  `=wasMoved`(dest)
  dest.field = src.field
```

- **Do not write a custom `=sink` by default.** The compiler synthesizes it from `=destroy` + `copyMem`.
- **Do not add self-assignment checks.** Simple self-assignments are eliminated by the compiler.
- **Do not bypass child hook semantics** with `copyMem` unless explicitly intended.

### `=copy`

```nim
proc `=copy`*(dest: var T; src: T) =
  if dest.field == src.field: return   # self-assignment protection
  `=destroy`(dest)
  `=wasMoved`(dest)
  dest.field = duplicateResource(src.field)
```

- **Self-assignment protection is mandatory.** Without it, `x = x` destroys the source.
- For move-only types, mark as `{.error.}`:

```nim
proc `=copy`*(dest: var T; src: T) {.error.}
```

Note: `{.error: "msg".}` will NOT be emitted. Only bare `{.error.}` works.

### `=dup`

```nim
proc `=dup`*(src: T): T {.nodestroy.} =
  result = T(len: src.len, cap: src.cap, data: nil)
  # ... copy or share ...
```

- `=dup(x)` is an optimized replacement for `wasMoved(dest); =copy(dest, x)`.
- For shared handles, increments counter instead of deep-copying.

### `=trace`

```nim
proc `=trace`*(x: var T; env: pointer) =
  if x.data != nil:
    for i in 0..<x.len:
      `=trace`(x.data[i], env)
```

Add `=trace` only when: manually owned storage + stored values can form ORC cycles + using `--mm:orc`.

## Move semantics

- `move(x)` forces move. Source is left in moved-from state.
- `ensureMove(x)` is a compile-time annotation. Static error if move not provable. Works with rvalues and `sink` params only.
- `sink` parameters are **affine**: callee may or may not consume the value.
- Compiler inserts copies (`=dup` or `=copy`) when sink argument is not last use.
- Self-assignments: `x = x` is eliminated for `=sink`. **Required** in `=copy`.
- `swap` uses `copyMem`. Objects with self-pointers not supported.

## Hook declaration order

Declare hooks before procs that use the type. Only templates are safe between type and hooks.

## Verification

```bash
nim c --mm:orc --expandArc:nameOfFunction yourfile.nim
```

Shows every `=destroy`, `=wasMoved`, `=sink`, `=copy`, `=dup` the compiler inserts.

Test: move, overwrite, copy independence, dup independence, destroy-after-move, sink from temporaries, self-copy.

## Common mistakes

| Mistake | Why it's wrong |
|---------|---------------|
| Setting fields to nil inside `=destroy` | `=destroy` takes `T`, not `var T`. Use `=wasMoved` for that. |
| No sentinel check in `=destroy` | Double-free after move |
| Self-assignment check in `=sink` | Compiler eliminates simple self-assignments |
| Missing self-assignment protection in `=copy` | Destroys source |
| Custom `=sink` when synthesized is fine | Unnecessary |
| `copyMem` in `=sink` bypassing child hooks | Breaks ownership |
| `ensureMove` on lvalue with destructor | Compile error |
| `{.error: "msg".}` on `=copy` | Compiler ignores custom messages |
