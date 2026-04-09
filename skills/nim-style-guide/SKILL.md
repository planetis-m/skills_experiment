---
name: nim-style-guide
description: Enforce idiomatic, readable Nim with formatting, naming, call-style, control-flow, and local declaration conventions.
---

# Preamble

Use this skill to keep Nim code readable, consistent, and intentionally opinionated.
Larger examples live under `references/`.

# Rules

## Formatting

- Indent with 2 spaces. Do not use tabs.
- Keep lines reasonably short and wrap before they become hard to scan.
- Do not align columns with extra spaces.
- Use `a..b` unless spaces help with unary operators.
- Indent wrapped declarations, calls, and conditions one extra level.

## Imports And Naming

- Prefer `std/...` imports for stdlib modules.
- Use `import std/[a, b, c]` for broad imports.
- Use `from std/foo import bar, baz` when only a small API slice is needed.
- Types use `PascalCase`.
- Procs, funcs, iterators, templates, vars, and fields use `camelCase`.
- Use normal word casing such as `parseUrl` and `httpStatus`.
- For non-pure enums, prefix values such as `pcFile`. For pure enums, use `PascalCase`.

## Proc, Func, Template, Macro

- Default to `proc`.
- Use `func` for side-effect-free helpers and accessors.
- Use `template` only for tiny substitutions or tiny zero-overhead wrappers.
- If a helper has its own control flow or mutable local state, use `proc` or `func`.
- Use `macro` only when syntax transformation is required.

## Calls, Locals, And Types

- Prefer compact wrapped calls over one-argument-per-line call blocks.
- Prefer UFCS when it reads like an accessor.
- Use `let` by default.
- Use `var` only for values that mutate.
- Keep local declarations close to first use.
- Keep `type` blocks at module scope.
- Group related fields with the same type when it improves readability.
- When using object constructors, specify the fields you mean to override and omit the ones that should keep their normal defaults.

## Control Flow

- Prefer straightforward `if/elif/else` and explicit loop conditions.
- Use early `return` for real guard exits or found values.
- Keep one clear normal success path and use `result = ...` for it.
- Do not add early `return` only to avoid nesting.
- `continue` is banned. Restructure the branch instead.

# Workflow

1. Pick the right callable kind: `proc`, `func`, `template`, or `macro`.
2. Write imports in `std/...` form and narrow them when practical.
3. Keep one obvious normal path through each proc.
4. Use names, wrapping, and locals that stay easy to scan.
5. Remove formatting noise before finishing.

# Common Mistakes

| Mistake | Why it is wrong |
|---------|-----------------|
| Using `template` for general helper logic | Hides ordinary control flow and makes debugging harder. |
| Using `proc` for obviously pure accessor-style helpers | Loses a useful signal that the helper has no side effects. |
| Writing wide one-argument-per-line call blocks by default | Uses vertical space without improving readability. |
| Using `var` for values that never mutate | Hides which locals actually change. |
| Using `continue` | Usually means the loop branches can be structured more clearly. |
| Restating every object field in a constructor | Adds noise and can hide which fields are intentionally overridden instead of left at their defaults. |

# References

- `references/core_patterns.md`: Opinionated default patterns for imports, callable kinds, wrapping, locals, and fields.

# Changelog

- 2026-04-09: Added the in-repo verified `nim-style-guide` skill as a standalone, opinionated style guide.
- 2026-04-09: Added verified object-constructor default-field guidance and a `nim-style-guide` dataset with compile/run tests for technical claims.
