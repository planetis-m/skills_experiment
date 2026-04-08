# Domain Safety with Distinct Types

Using `distinct` to prevent accidental mixing of conceptually different values.

## Pattern

```nim
type
  Port = distinct uint16
  Color = distinct int
  BackwardsIndex = distinct int

# Borrow common operations
proc `==`*(a, b: Port): bool {.borrow.}
proc `$`*(p: Port): string {.borrow.}

proc `==`*(a, b: Color): bool {.borrow.}
proc `$`*(c: Color): string {.borrow.}
```

## What distinct gives you

1. **Compile-time type safety** — cannot pass a `uint16` where `Port` is expected.
2. **No implicit arithmetic** — `Port(80) + Port(1)` won't compile unless you
   define `+` for Port.
3. **Borrowed operations** — `{.borrow.}` gives you `==` and `$` from the base
   type without writing implementations.

## Stdlib examples

- `system/indices.nim`: `BackwardsIndex = distinct int` — used by `^` operator
  for reversed array access.
- `pure/colors.nim`: `Color = distinct int` — RGB values, no accidental
  mixing with plain integers.
- `pure/nativesockets.nim`: `Port = distinct uint16` — network ports, not
  just numbers.
- `pure/asyncdispatch.nim`: `AsyncFD = distinct int` (or `distinct cint`) —
  file descriptors, not integers.

## When to use

- When two concepts share a base type but must not be mixed (Port vs uint16).
- When you want to restrict available operations (no arithmetic on Colors).
- When you want to add semantic meaning to a primitive type (thread ID,
  file handle, entity ID).

## When not to use

- When you actually want full arithmetic from the base type — use a type
  alias instead.
- When the overhead of defining borrow procs isn't worth it for purely
  internal use.
