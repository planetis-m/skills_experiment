# Constructor and Conversion Patterns

Patterns from the standard library for init/new constructors and toX conversions.

## Value vs Ref constructors

```nim
# Value type constructor — returns T
proc initTable*[A, B](initialSize = defaultInitialSize): Table[A, B] =
  result = Table[A, B]()

# Ref type constructor — returns ref T
proc newTable*[A, B](initialSize = defaultInitialSize): TableRef[A, B] =
  new(result)
  result[] = initTable[A, B](initialSize)

# Ref type from data
proc newTable*[A, B](pairs: openArray[(A, B)]): TableRef[A, B] =
  result = newTable[A, B]()
  for key, val in items(pairs): result[key] = val
```

**Convention:** `initX` for stack/value types, `newX` for heap/ref types.
Default parameters let callers omit tuning knobs.

## Conversion constructors (toX)

```nim
proc toTable*[A, B](pairs: openArray[(A, B)]): Table[A, B] =
  result = initTable[A, B]()
  for key, val in items(pairs): result[key] = val

proc toDeque*[T](x: openArray[T]): Deque[T] =
  result = initDeque[T]()
  for item in items(x): result.addLast(item)
```

**Convention:** `toX` converts from common inputs. Overload on input type,
don't invent different names.

## Ref type pairing

When providing both value and ref versions:
- `Table[A, B]` (value) paired with `TableRef[A, B] = ref Table[A, B]`
- Mirror the full accessor surface: `[]`, `[]=`, `hasKey`, `getOrDefault`,
  `mgetOrPut`, iterators
- `initX` for value, `newX` for ref

## Key points

- Use default params for optional configuration (initialSize, capacity).
- Name conversions `toX`, not `fromY` or `createFromX`.
- Ref constructors delegate to value constructors — don't duplicate init logic.
