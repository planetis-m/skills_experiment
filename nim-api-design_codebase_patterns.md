# Codebase Patterns for nim-api-design

Collected from `~/Projects/Nim/lib/` (std lib) and `~/Projects/Nim/compiler/`.

## 1. Shared Error Helper Pattern (`{.noinline, noreturn.}`)

**std lib examples:**
- `pure/collections/tables.nim:230`: `proc raiseKeyError[T](key: T) {.noinline, noreturn.}`
- `pure/dynlib.nim:62`: `proc raiseInvalidLibrary*(name: cstring) {.noinline, noreturn.}`
- `pure/parseutils.nim:429`: `proc integerOutOfRangeError() {.noinline, noreturn.}`
- `std/assertions.nim:35`: `proc raiseAssert*(msg: string) {.noinline, noreturn, nosinks.}`
- `std/syncio.nim:160`: `proc raiseEIO(msg: string) {.noinline, noreturn.}`

**compiler example:**
- `compiler/lineinfos.nim:335`: `proc raiseRecoverableError*(msg: string) {.noinline, noreturn.}`

**Pattern:** One shared helper per error category, marked `{.noinline, noreturn.}`. This prevents code bloat at every call site and gives consistent error messages.

## 2. lent T for Read Accessors

**std lib examples (extensive):**
- `tables.nim:316`: `proc \`[]\`*[A, B](t: Table[A, B], key: A): lent B`
- `deques.nim:118`: `proc \`[]\`*[T](deq: Deque[T], i: Natural): lent T {.inline.}`
- `deques.nim:312,327`: `proc peekFirst*[T](deq: Deque[T]): lent T {.inline.}`
- `critbits.nim:307`: `func \`[]\`*[T](c: CritBitTree[T], key: string): lent T {.inline.}`
- `heapqueue.nim:75`: `proc \`[]\`*[T](heap: HeapQueue[T], i: Natural): lent T {.inline.}`
- `system/excpt.nim:575`: `proc getStackTraceEntries*(e: ref Exception): lent seq[StackTraceEntry]`

**Pattern:** Read-only accessors return `lent T` with `{.inline.}`. This is pervasive in the stdlib — all collection `[]` operators, iterators (`items`, `values`, `keys`), and peek operations use it.

## 3. var T Overload Pairing

**std lib examples:**
- `deques.nim:129`: `proc \`[]\`*[T](deq: var Deque[T], i: Natural): var T {.inline.}` (paired with `lent T` version at line 118)
- `deques.nim:342`: `proc peekFirst*[T](deq: var Deque[T]): var T {.inline.}` (paired with `lent T` at 312)
- `critbits.nim:317`: `func \`[]\`*[T](c: var CritBitTree[T], key: string): var T {.inline.}`
- `tables.nim:339`: `proc \`[]\`*[A, B](t: var Table[A, B], key: A): var B`

**Pattern:** For each `lent T` accessor on a collection/container, there is a `var T` overload taking `var Container`. The `var` version is used for mutation: `deq[0] = newValue`. This is only meaningful for reference-like/complex types (strings, seqs, objects) — scalars don't benefit.

## 4. Accessor Error Routing (tables.nim)

```nim
proc raiseKeyError[T](key: T) {.noinline, noreturn.} =
  when compiles($key):
    raise newException(KeyError, "key not found: " & $key)
  else:
    raise newException(KeyError, "key not found")

template get(t, key): untyped =
  var hc: Hash
  var index = rawGet(t, key, hc)
  if index >= 0: result = t.data[index].val
  else:
    raiseKeyError(key)

proc `[]`*[A, B](t: Table[A, B], key: A): lent B =
  get(t, key)
```

**Key insight:** The actual lookup logic is in a `template` (`get`), shared between `lent` and `var` overloads. The error is routed through `raiseKeyError`. This is a clean separation of concerns.

## 5. Named Object Types for Semantic Data

**compiler examples (ast.nim):**
- `PNode` = ref object with kind field (object variant)
- `PSym` = ref object with typed fields
- `PType` = ref object
- `ConfigRef` = ref object

**Pattern:** All semantic data uses named types. Tuples are used only for trivial local pairs (e.g., `tuple[key: A, val: B]` in internal table entries).

## 6. Parameter Constraints (Natural, Positive, etc.)

**std lib examples:**
- `deques.nim:118`: `i: Natural` — indices use `Natural` (non-negative int)
- `deques.nim:75`: `HeapQueue` uses `Natural` indexing

**Pattern:** Use Nim's range types and type aliases (`Natural`, `Positive`, range types) to enforce constraints at the type level rather than with manual checks.

## 7. Inline Accessors

**std lib pattern:**
- `deques.nim:118`: `{.inline.}` on `lent T` accessors
- `critbits.nim:307`: `{.inline.}` on `lent T` accessors
- `heapqueue.nim:75`: `{.inline.}` on `lent T` accessors
- `compiler/ast.nim:91`: `proc kind*(s: PSym): TSymKind {.inline.}`

**Pattern:** Simple field access and index accessors are marked `{.inline.}` to avoid call overhead. Error helpers are `{.noinline.}` to avoid code duplication.

## 8. withValue Template (tables.nim)

```nim
template withValue*[A, B](t: var Table[A, B], key: A, value, body: untyped) =
```

**Pattern:** When you need "get or handle missing" semantics without exceptions, use a template-based API (`withValue`). This provides an escape hatch from the default raise-on-missing behavior.
