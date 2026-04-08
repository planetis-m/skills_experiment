---
name: nim-api-design
description: Design Nim APIs with clear contracts, coherent data models, and accessor behavior.
---

# Nim API Design

Use this skill when shaping the public surface of a new Nim library.
Default to one clear API path. Do not teach every pattern the stdlib happens
to contain.

Reference examples live in `references/`.

## Rules

### Pick one public shape

- Default to one public representation for a library type.
- Start with a value type. Add a `ref` wrapper only when shared identity,
  aliasing, or long-lived mutable handles are part of the contract.
- Use named `object` types for public semantic data.
- Do not return public status tuples such as `(ok: bool, payload: T, msg: string)`.

### Keep contracts in types

- Keep type-level contracts as strong as possible. Do not weaken `Positive`,
  `Natural`, or a range type to `int` and then re-add weaker runtime checks.
- Do not add redundant checks that restate an existing parameter contract
  unless you are crossing a trust boundary.
- Use `distinct` types for semantically different values that share the same
  base type. Borrow only the operations that should remain public.

### Constructor surface

- Value types use `initX()` and return `T`.
- Use one `toX()` name for common conversions. Overload on input type instead
  of inventing parallel constructor names.
- Constructor tuning knobs should have sensible default values so the
  zero-argument path remains the default.
- If a `ref` wrapper is genuinely needed, use `newX()` and delegate to the
  value constructor instead of duplicating setup logic.

### Accessor surface

- Read accessors that borrow from fields should return `lent T` and usually be
  `{.inline.}`.
- Add `var T` overloads only for reference-like fields (`string`, `seq`,
  nested objects) when caller mutation is part of the API.
- Never return `var` for scalars such as `int`, `float`, `bool`, or enums.
- In `lent` and `var` accessors, return directly from the owner field or
  indexed field. Do not route through a temp local.

### Error surface

- Missing required data or invalid lookup should raise a specific catchable
  exception through one shared `{.noinline, noreturn.}` helper.
- Do not silently return a default value for required data.
- Use `{.raises.}` annotations on leaf helpers or stable public contracts when
  they clarify the exception surface and are easy to keep accurate.

### Public boundary

- Export only the stable public surface. Keep helper procs unexported.
- Use descriptive public names. Avoid generic names such as `Result`, `Data`,
  or `handleError`.

## Workflow

1. Define the public data model.
   Choose one primary representation and name every public semantic type.
2. Write the constructor surface.
   Add `initX()` first, then `toX()` for common inputs. Add `newX()` only if
   the type truly needs a ref wrapper.
3. Write the read surface.
   Use `lent` accessors with direct field access and one shared error helper.
4. Add mutation only where the API needs it.
   Add `var` accessors for mutable reference-like fields only.
5. Tighten the contract.
   Use range types, `distinct`, and selective `{.raises.}` annotations.
6. Verify under ORC.
   Compile with `--mm:orc` and check that accessors do not use temp locals or
   leak scalar mutation.

## Common Mistakes

| Mistake | Why it's wrong |
|---------|---------------|
| Weakening `Positive` or `Natural` to `int` and re-checking manually | Loses a stronger type-level contract and adds dead or weaker runtime checks |
| Returning `(ok: bool, payload: T, msg: string)` | Pushes error handling onto every caller and leaves the result shape ambiguous |
| Teaching both value and ref representations by default | Creates two API paths when most library types only need one |
| `var int` accessor for a field | Leaks mutable access to internal scalar state |
| `let temp = obj.field[i]; result = temp` in a `lent` accessor | ORC rejects the borrow because the temp escapes its stack frame |
| Silent default on missing required data | Hides bugs and makes absence indistinguishable from a legitimate value |
| Repeating error-raising code in each accessor | Bloats code and fragments the public error surface |
| Using stdlib-only escape hatches such as `{.since.}` or `withValue` as general guidance | They are specialized patterns, not a default blueprint for a new library |

## References

- `references/accessor_pair.md` — Minimal lent/var accessor pair with one shared error helper
- `references/collection_accessors.md` — One coherent container API surface with direct-field accessors
- `references/constructors.md` — `initX`/`toX` default path and an optional `newX` wrapper
- `references/distinct_types.md` — Domain types with `distinct` and borrowed operations
- `references/result_types.md` — Named result objects and why status tuples stay out of public APIs
