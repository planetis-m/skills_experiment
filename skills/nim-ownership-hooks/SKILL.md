---
name: nim-ownership-hooks
description: Design, review, and implement Nim ARC/ORC ownership hooks and move semantics for value types, containers, shared handles, and manually allocated storage. Use when working on `=destroy`, `=wasMoved`, `=sink`, `=copy`, `=dup`, `=trace`, `sink` parameters, `lent` accessors, or ARC/ORC ownership bugs and warnings in Nim code.
---

# Nim Ownership Hooks and Move Semantics

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

No custom hooks. Use `lent T` for immutable accessors that should borrow instead of copying:

```nim
proc `[]`(x: MyContainer; i: int): lent Elem =
  x.data[i]
```

`lent T` is a hidden pointer, like `var T` but immutable. No destructor is injected for `lent T` or `var T` expressions.

### Move-only owner

For exclusive resources (manually allocated buffers, single-owner handles):

```nim
proc `=destroy`*(x: var T) =
  if x.data != nil:
    dealloc(x.data)
    x.data = nil

proc `=wasMoved`*(x: var T) =
  x.data = nil

proc `=copy`*(dest: var T; src: T) {.error.}
```

Optionally add a custom `=sink` only when the compiler-synthesized version (which uses `=destroy` + `copyMem`) is not acceptable.

### Deep-owning container

For containers that manually allocate backing storage and own their elements:

```nim
proc `=destroy`*(x: var T) =
  if x.data != nil:
    for i in 0..<x.len:
      `=destroy`(x.data[i])
    dealloc(x.data)
    x.data = nil

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

`=copy` and `=dup` usually retain or share a payload instead of deep-copying it. `=dup` increments the reference count:

```nim
proc `=dup`*(x: Ref[T]): Ref[T] =
  result = x
  if x.rc != nil:
    inc x.rc[]
```

Do not force one ownership model onto another. A shared handle should not become move-only just because it has a destructor.

## Hook implementations

### `=destroy`

```nim
proc `=destroy`*(x: T) =
  if x.field != nil:         # check moved-from sentinel first
    freeResource(x.field)
```

- Accepts `T` or `var T` parameter.
- Implicitly annotated `.raises: []`. A destructor should not raise exceptions.
- Check the moved-from sentinel (usually `nil` or a default handle) before freeing.
- Destroy nested values before freeing raw storage.
- `=wasMoved(x)` followed by `=destroy(x)` cancel each other out — the compiler exploits this optimization.

### `=wasMoved`

```nim
proc `=wasMoved`*(x: var T) =
  x.field = nil
```

Sets the object to its default state so `=destroy` becomes a no-op. Set the smallest faithful moved-from state.

### `=sink`

```nim
proc `=sink`*(dest: var T; src: T) =
  `=destroy`(dest)
  `=wasMoved`(dest)
  dest.field = src.field
```

- **Do not write a custom `=sink` by default.** When not provided, the compiler synthesizes it from `=destroy` + `copyMem`. This is efficient and correct for most types.
- When a custom `=sink` is required, destroy the destination first, then transfer fields directly.
- **Do not add self-assignment checks to `=sink`.** Simple self-assignments (`x = x`, `x.f = x.f`, `x[0] = x[0]` with compile-time-known indices) are transformed into a no-op by the compiler.
- **Do not bypass child hook semantics** with `copyMem` or whole-object raw moves unless that behavior is explicitly intended.

### `=copy`

```nim
proc `=copy`*(dest: var T; src: T) =
  if dest.field == src.field: return   # self-assignment protection
  `=destroy`(dest)
  `=wasMoved`(dest)
  dest.field = duplicateResource(src.field)
```

- **Self-assignment protection is mandatory.** Without it, `x = x` destroys the source before copying.
- For move-only types, mark as `{.error.}` instead of inventing partial copy semantics:

```nim
proc `=copy`*(dest: var T; src: T) {.error.}
```

Note: `{.error: "custom message".}` will NOT be emitted by the compiler. Only bare `{.error.}` prevents the copy at compile-time.

### `=dup`

```nim
proc `=dup`*(src: T): T {.nodestroy.} =
  result = T(len: src.len, cap: src.cap, data: nil)
  if src.data != nil:
    result.data = cast[typeof(result.data)](alloc(result.cap * sizeof(Elem)))
    for i in 0..<result.len:
      result.data[i] = `=dup`(src.data[i])
```

- `=dup(x)` is an optimized replacement for `wasMoved(dest); =copy(dest, x)`.
- Present it when a custom `=copy` is overridden, as an optimized duplication path.
- For deep-owning containers, allocates fresh storage and duplicates each live element.
- For shared handles, retains or increments a reference count.

### `=trace`

```nim
proc `=trace`*(x: var T; env: pointer) =
  if x.data != nil:
    for i in 0..<x.len:
      `=trace`(x.data[i], env)
```

Add `=trace` **only when all** of these are true:

1. The type manually owns storage (e.g., `ptr UncheckedArray[T]`)
2. Stored values can participate in ORC cycles (contain `ref` / closures)
3. Using `--mm:orc`

Without `=trace`, cyclic data structures constructed with the container may leak memory, but memory safety is not compromised. `=trace` is only used by `--mm:orc`.

There is a mutual use problem: whichever of `=destroy`/`=trace` is defined first will auto-generate a version of the other. To prevent conflicts, forward-declare the second hook.

## Move semantics

### `move` and `ensureMove`

- `move(x)` **forces** a move operation. It transfers ownership and calls `=wasMoved` on the source. Use when you need to explicitly move a value into its final position.
- `ensureMove(x)` is a **compile-time annotation** (no runtime operation). It causes a static error if the compiler cannot prove that a move would be safe. Works reliably with rvalues and `sink` parameters. Does NOT work on lvalues where the compiler would need to insert an implicit copy (e.g., when the source is used afterward, including its destructor).

```nim
# Valid: rvalue, always last use
let valid = ensureMove makeValue()

# Valid: sink parameter
proc p(x: sink T) = ...
let alsoValid = ensureMove sinkParam

# Invalid: lvalue with destructor still in scope
# let invalid = ensureMove normalParam  # compile error
```

### `sink` parameters

- A `sink` parameter means the proc takes ownership of the value.
- Sink parameters are **affine, not linear**: the callee may consume the value once, or not at all. This enables signatures like `proc put(t: var Table; k: sink Key, v: sink Value)` where ownership is conditional.
- If the compiler cannot prove the argument is the last use of the source, it inserts a copy (`=dup` or `=copy`) before passing it.
- Object and tuple fields are treated as separate entities for the last-use analysis:

```nim
let tup = (Obj(), Obj())
consume tup[0]    # ok, only tup[0] consumed, tup[1] still alive
echo tup[1]
```

- Sink parameter inference can be enabled with `--sinkInference:on` or `{.push sinkInference: on.}`. Disable per-routine with `{.nosinks.}`.

### Self-assignment handling

The compiler handles self-assignments as follows:

1. **Simple cases** (`x = x`, `x.f = x.f`, `x[0] = x[0]` with compile-time-known indices) are transformed into a no-op. No hooks are called.
2. **Complex cases** (`x = f(x)`, `x = select(cond, x, y)`) are rewritten using `=sink` with careful blitting to preserve correctness. The compiler moves the source into a temporary, passes it to `=sink`, and this handles self-assignment correctly by design.

Consequences:
- `=sink` does **not** need self-assignment checks.
- `=copy` **must** protect against self-assignment.

### `swap`

`system.swap` is a builtin that swaps every field via `copyMem`. It is NOT implemented as `let tmp = move(b); b = move(a); a = move(tmp)`. Objects containing internal self-pointers are not supported.

## Hook lifting

Hooks for tuple types `(A, B, ...)` are generated by lifting the hooks of `A`, `B`, etc. The same applies to `object` and `array`. If a field's type already has custom hooks, the enclosing type gets correct compiler-generated hooks for free. Compiler-generated hooks for objects can be overridden.

## Hook declaration order (phase ordering)

The compiler eagerly generates implicit hooks at strategic points. If a custom hook appears too late, the compiler will error. The trigger points are:

1. `let/var x = ...` — hooks generated for `typeof(x)`
2. `x = ...` — hooks generated for `typeof(x)`
3. `f(...)` — hooks generated for `typeof(f(...))`
4. Every `sink T` parameter — hooks generated for `typeof(x)`

**Always declare custom hooks before any proc, converter, iterator, or generic instantiation that mentions the type.** `importc` procs are opaque and do not trigger hook generation. Only templates may safely appear between the type definition and the hooks.

If a hook body needs a shared helper, write it as a template directly before the hooks.

## `{.nodestroy.}` pragma

The `{.nodestroy.}` pragma inhibits all hook injections for a proc. Use it to specialize object traversal, e.g., to avoid deep recursions when destroying tree structures by using an explicit stack.

When using `{.nodestroy.}`, you are responsible for calling `=destroy` manually on anything that needs it.

## `{.cursor.}` pragma

Breaks up reference-counting cycles declaratively. A `{.cursor.}` field is a non-owning raw pointer — not reference-counted, no runtime checks. Not equivalent to C++'s `weak_ptr`.

```nim
type
  Node = ref object
    left: Node             # owning ref
    right {.cursor.}: Node # non-owning ref
```

The cursor pragma also prevents construction/destruction pairs and can be used to avoid refcounting overhead when iterating linked structures:

```nim
var it {.cursor.} = listRoot
while it != nil:
  use(it)
  it = it.next
```

Cursor inference (copy elision) is performed automatically: in `dest = src`, if neither `dest` nor `src` is mutated afterward, the copy is elided. Local variables and locations derived from formal parameters are easy to analyze.

## Verification

After every hook edit, inspect the compiler's intermediate output and run focused tests.

### Inspect with `--expandArc`

```bash
nim c --mm:orc --expandArc:nameOfFunction yourfile.nim
```

This prints the expanded representation showing every `=destroy`, `=wasMoved`, `=sink`, `=copy`, and `=dup` the compiler inserts. Use this to:

- Confirm synthesized hooks match your intent
- Verify self-assignments are eliminated (no hooks emitted for `x = x`)
- Check that move-only types use `=wasMoved` instead of `=copy`
- See the exact destruction order in `finally` blocks
- Verify `=dup` is used for sink argument copies when available

This is the most reliable way to audit ownership behavior.

### Compile and run tests

Compile with `--mm:orc` and test these scenarios for container-like types:

1. Move into another variable — source is moved-from
2. Overwrite of existing owned data — old data freed
3. Copy independence — modifying copy does not affect original
4. Dup independence — modifying dup does not affect original
5. Destroy-after-move — destroy is a no-op on moved-from value
6. Sink assignment from temporaries — ownership transferred
7. Self-copy (`x = x`) — no corruption when `=copy` is custom

If the compiler emits ARC/ORC warnings, fix the ownership cause or document why the warning is acceptable.

## Common mistakes

| Mistake | Why it's wrong |
|---------|---------------|
| Custom hooks on auto-managed types | Compiler already handles it; wasted code |
| No sentinel check in `=destroy` | Double-free after move |
| Self-assignment check in `=sink` | Unnecessary; compiler eliminates simple self-assignments |
| Missing self-assignment protection in `=copy` | Destroys source before reading it |
| Custom `=sink` when synthesized is fine | Unnecessary complexity |
| `copyMem` in `=sink` bypassing child hooks | Breaks ownership chain for child types |
| Forgetting `=wasMoved` for move-only types | Moved-from object has dangling pointers |
| Forgetting `=trace` for ORC cycle-participating containers | Cyclic data leaks memory under ORC |
| Declaring helper procs before hooks | Triggers phase-order problem |
| `ensureMove` on lvalue with destructor | Compile error — destruction counts as a use |
| Adding `{.error: "msg".}` on `=copy` expecting custom message | Compiler ignores custom error messages on `=copy`; use bare `{.error.}` |
| Self-pointers in objects swapped via `swap` | `swap` uses `copyMem`; internal self-pointers break |
