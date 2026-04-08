---
name: nim-api-design
description: Design Nim APIs with clear contracts, coherent data models, and accessor behavior.
---

# Nim API Design

Rules for designing public-facing Nim APIs: proc contracts, result types,
accessor signatures, data-model choices, type safety, constructors, and
module boundaries.

Reference examples live in `references/`.

## Rules

### Proc contracts

- Keep type-level contracts as strong as possible. Do not weaken a contract
  (e.g. `Positive` → `int`) and then add manual runtime checks — the
  type-level contract is strictly better.
- Do not add redundant runtime checks that restate existing type or proc
  contracts unless required by a trust boundary (e.g. FFI or unchecked input
  from another module). A `Natural` parameter already rejects negatives;
  adding `if i < 0: raise ...` is dead code.

### Data model

- Use named `object` types for all semantic data that appears in public APIs.
- Use tuples only for short local values (pairs, triples). If a tuple grows
  beyond two or three fields, promote it to a named object.
- Do not return status tuples like `(ok: bool, payload: T, errorMessage: string)`.
  Use a named result type or raise instead.

### Type safety with distinct

- Use `distinct` types to prevent accidental mixing of conceptually different
  values that share the same base type (e.g. `BackwardsIndex = distinct int`,
  `Color = distinct int`, `Port = distinct uint16`).
- Provide `{.borrow.}` procs for `==` and `$` on distinct types so they remain
  usable for comparison and display.
- Distinct types do not inherit arithmetic from the base type — define only
  the operations that make semantic sense.

### Constructors

- Value types use `initX()` constructors returning `T` (e.g. `initTable`,
  `initDeque`, `initHeapQueue`). Ref types use `newX()` constructors returning
  `ref T` (e.g. `newTable`).
- Provide `toX()` conversion procs that accept `openArray` or other common
  inputs (e.g. `toTable`, `toDeque`, `toHeapQueue`). Overload on input type,
  don't invent different names.
- Use default parameter values for tuning knobs (e.g.
  `initialSize = defaultInitialSize`) so callers can omit them.
- When providing both value and ref versions of a type, mirror the full
  accessor surface on both.

### Accessor signatures

- Read-only accessors that borrow from object fields must return `lent T` with
  `{.inline.}`. This is the standard library pattern (Table.`[]`, Deque.`[]`,
  Deque.peekFirst, HeapQueue.`[]`, all `items`/`values`/`keys` iterators).
- Add `var T` overloads only for reference-like results (`string`, `seq`,
  objects) when mutation is part of the API. The stdlib pairs every `lent T`
  reader with a `var T` writer on collections (e.g. Deque.`[]` for both).
- Do **not** add `var T` overloads for scalar outputs (`int`, `float`, `bool`,
  enums). A `var int` return from a direct field reference *does* propagate
  mutations back to the source — it leaks mutable access to internal state.
  This is a design hazard, not just redundancy.
- In `lent` and `var` accessors, use direct field indexing (`result = obj.field[i]`).
  Never assign to a temp local and then return it — ORC will reject it with
  "escapes its stack frame".

### Error handling in accessors

- Invalid index and missing required data are contract violations: raise a
  specific exception (ValueError, KeyError, or a domain-specific type).
  Do not silently return a default value — it hides bugs downstream.
- Route all accessor errors through one shared helper proc marked
  `{.noinline, noreturn.}`. This prevents code bloat at every call site and
  gives consistent error messages. The stdlib does this: `raiseKeyError` in
  tables.nim, `raiseInvalidLibrary` in dynlib.nim, `raiseEIO` in syncio.nim,
  `raiseRecoverableError` in the compiler's lineinfos.nim.

### Parameter design

- Use Nim's range types and type aliases (`Natural`, `Positive`, `range[0..max]`)
  to enforce constraints at the type level rather than with manual checks.
- Prefer `sink` parameters for ownership transfer and `lent` for borrows in
  public APIs — these communicate intent at the type level.

### Exception surface

- Mark procs with `{.raises: [].}` when they cannot raise, to make the
  exception surface explicit. The compiler enforces this — a proc marked
  `{.raises: [].}` that calls a raising proc will fail to compile.
- Use `{.raises: [SpecificError].}` to enumerate exactly which exceptions a
  proc can raise.
- For APIs that need "get or handle missing" semantics without exceptions,
  provide a template-based escape hatch (like tables.nim's `withValue`).

### API evolution

- Document version requirements with `when (NimMajor, NimMinor) >= (x, y)`
  guards for user code. Note: `{.since.}` is a stdlib-internal pragma
  (defined in `std/private/since.nim`) and is not available in user code.
- Mark only the intended public API with `*`; keep all internal helpers
  unexported. A module should have a clear public surface — constructors,
  accessors, and mutation operations — with implementation details private.

## Workflow

1. **Define data types first.** Name every public data shape. If you're
   tempted to return a tuple, name it instead. Use `distinct` for domain safety.
2. **Write constructors.** `initX()` for value types, `newX()` for ref types.
   Add `toX()` conversions. Use default params for tuning.
3. **Design the read surface.** Write `lent T` accessors with `{.inline.}`.
   Route errors through a shared `{.noinline, noreturn.}` helper.
4. **Add mutation surface only where needed.** Add `var T` overloads for
   reference-like fields only. Never for scalars.
5. **Strengthen contracts.** Use `Natural`, `Positive`, range types, distinct
   types, and `{.raises.}` annotations to push checks into the type system.
6. **Verify.** Compile with `--mm:orc`. Check that `lent`/`var` accessors
   compile without borrow errors. Use `--expandArc` to inspect hook
   insertion if needed.

## Common Mistakes

| Mistake | Why it's wrong |
|---------|---------------|
| Weakening `Positive` → `int` + manual check | Loses compile-time protection; the manual check is weaker than the original type contract |
| Adding `if i < 0` inside a proc taking `Natural` | Dead code — `Natural` already rejects negatives |
| Returning `(ok: bool, payload: T, msg: string)` | Unnamed, untyped, and the boolean forces the caller to check manually instead of handling exceptions |
| `var int` accessor for a scalar field | Leaks mutable access to internal state — the caller can mutate your private field |
| `let temp = x.field; result = temp` in a `lent` accessor | ORC rejects: "temp escapes its stack frame" — use direct indexing |
| Silent `return ""` on missing data | Caller can't distinguish "missing" from "legitimately empty" — raise instead |
| Separate error-raising code in each accessor | Code bloat and inconsistent messages — use a shared `{.noinline, noreturn.}` helper |
| Using `{.since.}` pragma in user code | Stdlib-internal only — use `when (NimMajor, NimMinor) >= (x, y)` guards instead |
| Exporting internal helpers | Blurs the public/private boundary — keep implementation details unexported |

## References

- `references/accessor_pair.md` — Complete lent/var accessor pair with shared error helper
- `references/result_types.md` — Named result objects vs status tuples
- `references/collection_accessors.md` — Patterns from stdlib (Table, Deque, CritBitTree)
- `references/constructors.md` — init/new constructor and toX conversion patterns
- `references/distinct_types.md` — Domain safety with distinct types and borrow

## Changelog

- 2026-04-08 v2: Refinement cycle. Added 9 new claims (C13-C21) covering constructors, distinct types, raises annotations, API evolution, export discipline, template-based APIs, and ref-type pairing. 3 new tests (C17, C18, C20) all pass. Key correction: `{.since.}` is stdlib-internal, not available in user code.
- 2026-04-08 v1: Initial verification. 12 claims, 9/9 testable passed. Two nuances: (1) exception type in accessors is flexible; (2) var int propagates mutations back, making it a hazard.
