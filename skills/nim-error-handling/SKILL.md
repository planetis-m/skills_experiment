# Nim Error Handling

## 1. Preamble

Use this skill when choosing between exceptions, boundary translation, parse helpers, or multi-step pipeline failure handling.

## 2. Rules

**Raise clear, bounded, actionable errors.** Catch errors only where you can recover, translate across a boundary, or add required context.

- Prefer exception propagation over manual result-wrapper plumbing.
- Let pipeline errors bubble until the boundary where they become actionable.
- Convert low-level errors at module boundaries when needed for context or contracts.
- For bool-return parse helpers, catch `CatchableError` once at the helper boundary and return `false`.
- Do not silently swallow exceptions (empty `except` blocks).
- Do not add custom exception types unless callers handle them differently from existing types.
- Do not introduce ad-hoc result objects that pass only `ok`, `kind`, and `message` between steps.
- `CatchableError` is the base for all recoverable exceptions (`ValueError`, `IOError`, `OSError`, `JsonParsingError`, etc.). Use it when you want to catch anything that can be recovered from.

### Exception translation

At module boundaries, catch low-level exceptions and raise domain-specific ones with context:

```nim
try:
  discard doWork()
except CatchableError:
  raise newException(IOError, "doWork failed: " & getCurrentExceptionMsg())
```

### Parse helper pattern

For parse operations where callers want a bool, not an exception:

```nim
proc parseHelper[T](data: string; dst: var T): bool =
  result = false
  try:
    dst = fromJson(parseJson(data), T)
    result = true
  except CatchableError:
    result = false
```

Note: this catches **syntax errors** (invalid JSON). Type mismatches (e.g., `getInt` on a string node) return default values silently — the parse helper won't catch those.

## 3. Workflow

### Step 1: Identify the failure mode

| Failure mode | Strategy |
|-------------|----------|
| Programmer error (bug) | Let it crash. Don't catch. |
| Recoverable error | Propagate via exceptions until actionable boundary. |
| Parse/validation | Bool-return helper with `CatchableError` catch. |
| Cross-boundary | Translate exception type + add context. |

### Step 2: Raise at the source

Use existing exception types (`ValueError`, `IOError`, `OSError`) with descriptive messages. Only create custom types when callers need to handle them differently.

### Step 3: Propagate through intermediate steps

Do not catch and re-wrap at every step. Let exceptions bubble through the call chain.

### Step 4: Catch at the boundary

Catch only at the point where you can: recover, translate, or produce output.

### Step 5: Verify

- Every `except` block should do something useful (re-raise, translate, return, log).
- No empty `except` blocks (use `discard` only in rare deliberate suppression).
- `CatchableError` as the catch-all for recoverable errors.
- `getCurrentExceptionMsg()` for context in translation.

## Common mistakes

| Mistake | Why wrong |
|---------|-----------|
| Empty `except` block | Silently swallows errors, hiding bugs. |
| Catching at every intermediate step | Adds noise, prevents propagation. |
| Custom result types (`ok`+`kind`+`message`) | Reinvents exceptions poorly. |
| Custom exception types identical to existing ones | Adds hierarchy with no behavioral difference. |
| Catching `Exception` instead of `CatchableError` | Also catches `Defect` (unrecoverable bugs). |
| Using `fromJson` for type-checked parsing without validation | Type mismatches return defaults silently. |

## References

- `references/pipeline_error_handling.md` — multi-step pipeline with boundary catch
- `references/parse_helpers.md` — bool-return parse wrappers

## Changelog
- 2026-04-08: Initial version
