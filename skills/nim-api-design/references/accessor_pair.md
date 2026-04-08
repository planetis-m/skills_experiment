# Accessor Pair Pattern

Complete example showing lent/var accessor pairs with a shared error helper,
following the pattern used in stdlib tables.nim and deques.nim.

```nim
type
  ChatCreateResult = object
    choices: seq[Choice]

  Choice = object
    message: Message

  Message = object
    toolCalls: seq[ToolCall]

  ToolCall = object
    id: string

proc raiseAccessorError(msg: string) {.noinline, noreturn.} =
  raise newException(ValueError, msg)

proc ensureIndex(len, i: int) {.inline.} =
  if i < 0 or i >= len:
    raiseAccessorError("index " & $i & " out of range [0.." & $(len - 1) & "]")

# Read accessor — borrows, no copy
proc firstCallId*(x: ChatCreateResult; i = 0): lent string {.inline.} =
  ensureIndex(x.choices.len, i)
  if x.choices[i].message.toolCalls.len == 0:
    raiseAccessorError("no tool calls at choice " & $i)
  result = x.choices[i].message.toolCalls[0].id

# Mutable accessor — only for string, which is reference-like
proc firstCallId*(x: var ChatCreateResult; i = 0): var string {.inline.} =
  ensureIndex(x.choices.len, i)
  if x.choices[i].message.toolCalls.len == 0:
    raiseAccessorError("no tool calls at choice " & $i)
  result = x.choices[i].message.toolCalls[0].id
```

## Key points

- One shared `raiseAccessorError` marked `{.noinline, noreturn.}` — all errors
  go through this single point.
- Bounds check delegated to a small inline proc, not duplicated.
- `lent string` for reads (works on `let` holders), `var string` for mutation
  (requires `var` holder).
- Direct field indexing (`x.choices[i].message.toolCalls[0].id`) — no temp locals.
- No `var` overloads for scalar fields like `choices.len`.
