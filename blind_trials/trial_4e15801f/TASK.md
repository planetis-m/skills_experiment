# Task: Implement a small rule parser module in a readable, opinionated Nim style

Create a file called `subject_solution.nim`.

The goal is to judge code style and code shape, not algorithm difficulty.
The runtime behavior is fixed. The internal decomposition is your choice.

The judge may inspect helper kind, helper placement, loop shape, constructor use, local declarations, and unused code in addition to runtime behavior.
Small predicate helpers may be concise. Keep the exported parser procs easy to scan.

## Required public surface

These exact exported symbols must exist:

```nim
type
  ParseMode* = enum
    pmStrict,
    pmLenient

  RuleEventKind* = enum
    rekEof,
    rekAccept,
    rekSkip,
    rekReject

  RuleEvent* = object
    kind*: RuleEventKind
    normalized*: string
    reason*: string = ""

  RuleParser* = object
    mode*: ParseMode = pmStrict
    label*: string = "default"
    accepted*: seq[string]
    skipped*: int
    rejected*: int
    duplicates*: int

proc open*(p: var RuleParser; lines: openArray[string]; mode = pmStrict; label = "default")
proc next*(p: var RuleParser): RuleEvent
proc close*(p: var RuleParser)
proc renderSummary*(p: RuleParser): seq[string]
```

No other exports are required.

## Required behavior

Treat the parser as an incremental parser over a fixed input sequence of lines.

`open` rules:

- Store the provided lines inside the parser so `next` can read them later
- Reset the parser to a fresh state
- Keep the `mode` argument
- Keep the `label` argument

`next` rules:

- Read the next unread line and return one event
- If there are no more unread lines, return `RuleEvent(kind: rekEof)`
- Trim spaces and tabs around the current line
- If the trimmed line is empty:
  - in `pmStrict`, raise `ValueError`
  - in `pmLenient`, increment `skipped` and return `RuleEvent(kind: rekSkip, reason: "empty")`
- If the trimmed line starts with `#`, increment `skipped` and return `RuleEvent(kind: rekSkip, reason: "comment")`
- A valid rule line has exactly one `=`
- Trim spaces and tabs around both sides of `=`
- The key must be lowercased and may contain only `{'a'..'z', '0'..'9', '-', '_'}` after trimming
- The value must be lowercased and may contain only `{'a'..'z', '0'..'9', '-', '_', '/'}` after trimming
- The normalized accepted form is `<key>=<value>` in lowercase
- If the line is malformed or uses invalid characters:
  - in `pmStrict`, raise `ValueError`
  - in `pmLenient`, increment `rejected` and return `RuleEvent(kind: rekReject, reason: "invalid")`
- Accepted normalized rules are unique
- The first accepted occurrence wins
- If a normalized rule is accepted for the first time:
  - append it to `accepted`
  - return `RuleEvent(kind: rekAccept, normalized: <normalized>)`
- If a normalized rule was already accepted:
  - increment `duplicates`
  - return `RuleEvent(kind: rekSkip, normalized: <normalized>, reason: "duplicate")`

`close` rules:

- Reset the parser to its normal empty state
- After `close`, `accepted.len == 0`, `skipped == 0`, `rejected == 0`, `duplicates == 0`
- After `close`, `mode == pmStrict` and `label == "default"`

`renderSummary` rules:

- Return the lines in this exact order:
  - `summary <label>`
  - `mode <strict|lenient>`
  - one `accept <normalized>` line per accepted rule in original accepted order
  - `duplicates <N>`
  - `skipped <N>`
  - `rejected <N>`

## Required smoke run

Add a `when isMainModule:` block that checks all of these:

- Opening in lenient mode and calling `next` repeatedly on:
  `@[" user = Alice ", " ", "#note", "user=alice", "bad!", "path = Docs/Guide"]`
  yields, in order:
  - `RuleEvent(kind: rekAccept, normalized: "user=alice")`
  - `RuleEvent(kind: rekSkip, reason: "empty")`
  - `RuleEvent(kind: rekSkip, reason: "comment")`
  - `RuleEvent(kind: rekSkip, normalized: "user=alice", reason: "duplicate")`
  - `RuleEvent(kind: rekReject, reason: "invalid")`
  - `RuleEvent(kind: rekAccept, normalized: "path=docs/guide")`
  - `RuleEvent(kind: rekEof)`
- After that run:
  - `accepted == @["user=alice", "path=docs/guide"]`
  - `skipped == 2`
  - `duplicates == 1`
  - `rejected == 1`
- `renderSummary` then returns:
  `@["summary batch-a", "mode lenient", "accept user=alice", "accept path=docs/guide", "duplicates 1", "skipped 2", "rejected 1"]`
- In strict mode:
  - `open` on `@["bad!"]`
  - the first `next` raises `ValueError`
- `close` resets the parser back to the empty default state

Then print:

```nim
echo "SMOKE: PASS"
```

## Critical requirements

- Compile and run with `nim c -r --mm:orc subject_solution.nim`
- Keep the public export surface narrow; do not export internal helpers
- Remove unused imports
- Avoid dead declarations left over from refactoring

## Judge checklist

Score only these checks:

- compiles and runs with `nim c -r --mm:orc subject_solution.nim`
- runtime prints `SMOKE: PASS`
- `open`, `next`, `close`, and `renderSummary` match the required behavior
- accepted rules preserve original accepted order and the counters are correct
- the exported surface contains the required public symbols and no obvious extra exported internals
- no `continue` statement appears in the file
- no `type` block appears inside a proc
- helpers with their own control flow, if present, are `proc` or `func`, not `template`
- helper procs, if present, are top-level rather than nested inside exported procs
- no obvious one-argument-per-line call blocks are used where a compact wrapped call would fit naturally
- object construction does not restate defaulted fields when the defaults are intended to remain unchanged
- no unused imports are left in the file

After writing, verify it runs:

```bash
nim c -r --mm:orc subject_solution.nim
```
