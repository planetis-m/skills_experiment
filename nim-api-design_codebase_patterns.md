# Codebase Patterns for nim-api-design

Collected from `~/Projects/Nim/lib/`, excluding the JSON libraries.

## 1. Shared Error Helper Pattern (`{.noinline, noreturn.}`)

Examples:
- `pure/collections/tables.nim`: `raiseKeyError`
- `pure/dynlib.nim`: `raiseInvalidLibrary`
- `std/syncio.nim`: `raiseEIO`
- `pure/parseutils.nim`: `integerOutOfRangeError`

Pattern:
- One helper per error category.
- Marked `{.noinline, noreturn.}`.
- Accessors and low-level operations route failures through that helper.

## 2. `lent` for Read Accessors

Examples:
- `pure/collections/tables.nim`: `[]`
- `pure/collections/deques.nim`: `[]`, `peekFirst`
- `pure/collections/heapqueue.nim`: `[]`, `items`
- `pure/xmltree.nim`: read iterators

Pattern:
- Read accessors that borrow from owned storage return `lent T`.
- Small read accessors are commonly `{.inline.}`.

## 3. `var` Only for Intentional Mutation

Examples:
- `pure/collections/deques.nim`: mutable `[]`
- `pure/collections/tables.nim`: mutable `[]`
- `pure/xmltree.nim`: `mitems`

Pattern:
- `var` accessors exist where callers are meant to mutate stored data.
- Mutable iterator/accessor surfaces are separate from read-only ones.
- This is useful for reference-like or nested values, not for scalars.

## 4. Constructor Surface

Examples:
- Value constructors: `initDeque`, `initHeapQueue`, `initHashSet`, `initRand`
- Conversion constructors: `toDeque`, `toHeapQueue`, `toHashSet`
- Ref constructors: `newStringStream`, `newSocket`, `newConsoleLogger`, `newSelector`

Pattern:
- One main constructor path per type.
- Value types usually start with `initX`.
- Ref-only handle types use `newX`.
- `toX` is used for common conversions into an already-chosen representation.

## 5. One Main Representation Is The Default

Examples:
- Value-only public types: `Deque`, `HeapQueue`, `HashSet`, `Time`, `Duration`
- Ref-only public handles: `Stream`, `Socket`, `Logger`, `Regex`
- Paired value/ref public types: `Table` and `TableRef`

Pattern:
- Most modules expose one primary representation.
- Paired value/ref surfaces exist, but they are specialized and should not be
  treated as the default advice for every new library type.

## 6. Type-Level Contracts

Examples:
- `Natural` indices in `deques.nim` and `heapqueue.nim`
- `MonthdayRange`, `NanosecondRange`, `IsoWeekRange` in `times.nim`
- `Port = distinct uint16` in `nativesockets.nim`
- `Color = distinct int` in `colors.nim`

Pattern:
- Keep constraints in the type system when possible.
- Use `distinct` when two values share a base type but should not mix.

## 7. `raises` Is Real But Selective

Examples:
- `std/assertions.nim`: `failedAssertImpl` with `raises: []`
- `pure/md5.nim`: core helpers with `raises: []`
- `pure/pegs.nim`: explicit `raises: [EInvalidPeg]`
- `pure/net.nim`: selected socket and SSL helpers with explicit raises lists

Pattern:
- `raises` annotations are compiler-enforced and useful.
- The libraries use them selectively on leaf helpers and stable public
  contracts, not as a blanket style for every proc.
