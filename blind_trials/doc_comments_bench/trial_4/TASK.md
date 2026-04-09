# Task: Document a small Nim module and verify it with nim doc

Create a file called `subject_solution.nim`.

The goal is to judge Nim doc-comment placement and rendered output, not parser difficulty.

Examples are not required for this task.

## Required public surface

These exact exported symbols must exist:

```nim
const
  DefaultDepth* = 8

type
  ParseMode* = enum
    pmStrict,
    pmLenient

  ParseConfig* = object
    maxDepth*: Positive
    allowTabs*: bool

proc parseCount*(s: string; cfg: ParseConfig; mode = pmStrict): int
```

Also include one private helper proc of your choice that is not exported.

## Required runtime behavior

Implement `parseCount` with this behavior:

- If `s.len == 0`, return `0`
- Treat commas as separators
- In `pmStrict`, raise `ValueError` on any empty segment
- In `pmLenient`, skip empty segments
- Trim spaces around segments
- If the accepted segment count exceeds `cfg.maxDepth`, raise `ValueError`

## Required doc content

Write doc comments so that rendered docs include these exact phrases:

- module docs: `Parsing helpers for simple comma-separated counts.`
- `DefaultDepth`: `Default maximum accepted segment count.`
- `ParseMode`: `Controls how empty segments are handled.`
- `pmStrict`: `Rejects empty segments.`
- `pmLenient`: `Skips empty segments.`
- `ParseConfig`: `Options that control count parsing.`
- `maxDepth`: `Maximum number of accepted segments.`
- `allowTabs`: `Whether tab characters are treated as whitespace.`
- `parseCount`: `Parses comma-separated segments and returns their count.`

The private helper must not appear in rendered docs.

## Required smoke run

Add a `when isMainModule:` block that checks:

```nim
let cfg = ParseConfig(maxDepth: 3, allowTabs: true)
```

The smoke run must assert all of these:

- `parseCount("", cfg) == 0`
- `parseCount("a,b,c", cfg) == 3`
- `parseCount("a, b ,c", cfg) == 3`
- `parseCount("a,,c", cfg, pmLenient) == 2`
- `parseCount("a,,c", cfg, pmStrict)` raises `ValueError`
- `parseCount("a,b,c,d", cfg, pmLenient)` raises `ValueError`

Then print:

```nim
echo "SMOKE: PASS"
```

## Critical requirements

- The file must compile and run with `nim c -r --mm:orc subject_solution.nim`
- `nim doc --outdir:htmldocs subject_solution.nim` must succeed
- Write source comments only; do not edit generated output
- Do not add `runnableExamples:`

## Judge checklist

Score only these checks:

- compiles and runs with `nim c -r --mm:orc subject_solution.nim`
- runtime prints `SMOKE: PASS`
- `nim doc --outdir:htmldocs subject_solution.nim` succeeds
- rendered docs contain the required module doc phrase
- rendered docs contain the required proc, const, type, enum value, and object field phrases
- the private helper does not appear in rendered docs
- no `runnableExamples:` block was added
- exported symbols are the ones documented in the rendered output

After writing, verify both commands:

```bash
nim c -r --mm:orc subject_solution.nim
nim doc --outdir:htmldocs subject_solution.nim
```
