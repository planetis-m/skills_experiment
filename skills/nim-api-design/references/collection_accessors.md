# Collection Accessor Patterns from the Standard Library

Patterns observed in `pure/collections/tables.nim`, `deques.nim`,
`critbits.nim`, and `heapqueue.nim`.

## Shared error helper (tables.nim)

```nim
proc raiseKeyError[T](key: T) {.noinline, noreturn.} =
  when compiles($key):
    raise newException(KeyError, "key not found: " & $key)
  else:
    raise newException(KeyError, "key not found")
```

- Uses `when compiles($key)` for conditional formatting — clean pattern.
- Marked `{.noinline, noreturn.}` — code size and consistency.
- Uses `KeyError` (a specific exception type), not generic `ValueError`.

## Shared lookup template (tables.nim)

```nim
template get(t, key): untyped =
  var hc: Hash
  var index = rawGet(t, key, hc)
  if index >= 0: result = t.data[index].val
  else:
    raiseKeyError(key)
```

- Both `lent T` and `var T` overloads call this same template.
- Lookup logic is written once, shared between both accessor variants.

## lent/var pairing (deques.nim)

```nim
proc `[]`*[T](deq: Deque[T], i: Natural): lent T {.inline.} =
  ## Read accessor — works on let holders
  ...

proc `[]`*[T](deq: var Deque[T], i: Natural): var T {.inline.} =
  ## Mutable accessor — allows deq[0] = newValue
  ...

proc peekFirst*[T](deq: Deque[T]): lent T {.inline.} = ...
proc peekFirst*[T](deq: var Deque[T]): var T {.inline, since: (1, 3).} = ...
```

- Index parameter uses `Natural` — type-level non-negative guarantee.
- Every read accessor has a `{.inline.}` mutable counterpart.
- The `var` version has a `since` pragma documenting when it was added.

## Iterator lending

```nim
iterator items*[T](deq: Deque[T]): lent T = ...
iterator mitems*[T](deq: var Deque[T]): var T = ...
iterator keys*[A, B](t: Table[A, B]): lent A = ...
iterator values*[A, B](t: Table[A, B]): lent B = ...
```

- All read iterators yield `lent T`; all mutable iterators yield `var T`.
- Naming convention: `mitems`/`mvalues`/`mpairs` for mutable variants.

## When to use

- Use these patterns when designing any container or lookup API.
- The lent/var pairing, shared error helper, and template-based lookup
  are battle-tested across the entire stdlib collections module.
