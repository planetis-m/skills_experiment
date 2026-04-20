---
name: nim-testing
description: Write and run Nim tests using block-based assertions, a central test runner, multi-configuration builds, sanitizer integration, and CI pipelines. Use when setting up a Nim test suite, writing isolated test cases, running tests across debug/release/danger modes, adding AddressSanitizer support, or configuring GitHub Actions CI for a Nim project.
---

# Nim Testing

Write and run isolated, deterministic Nim tests using `block`-based assertions instead of macro-heavy frameworks. Covers project layout, a central auto-discovering test runner, multi-configuration builds (debug, release, danger), and AddressSanitizer integration. All commands and patterns have been verified on Nim 2.3.1 with gcc 15 on Linux.

Extended examples and CI workflows live in `references/`.

## Rules

### Use `block`-based tests with `doAssert`

Prefer `block` + `doAssert` over `std/unittest`. Each test is isolated in its own `block`, produces clear output on failure, and exits explicitly.

```nim
block add_basic:
  doAssert add(1, 2) == 3

block greet_empty:
  doAssert greet("") == "hello "
```

`doAssert` raises `AssertionDefect` with the optional message on failure. The process exits with a non-zero code, so CI detects the failure.

### Use `when defined(danger)` for overflow-dependent tests

`-d:danger` disables overflow checks. Tests that depend on `OverflowDefect` must guard:

```nim
block add_overflow:
  when defined(danger):
    doAssert true
  else:
    var raised = false
    try:
      discard add(high(int) - 1, 2)
    except OverflowDefect:
      raised = true
    doAssert raised
```

### Project layout

```
project/
  src/
    mylib.nim
  tests/
    config.nims        # shared compiler switches for tests
    tester.nim         # central test runner (auto-discovers t*.nim)
    thelper.nim        # shared test helpers (optional)
    tbasic.nim         # individual test files
    tedge.nim
    terrors.nim
```

### Test file naming

Use `t` prefix followed by a short descriptive name:

- `tbasic.nim` — core functionality
- `tedge.nim` — edge cases and boundary values
- `terrors.nim` — error handling paths
- `tintegration.nim` — multi-module interactions

The runner auto-discovers all files matching `tests/t*.nim` (excluding itself and `thelper.nim`).

### `tests/config.nims` — shared test configuration

```nim
switch("path", "$projectdir/../src")
```

This resolves `import mylib` from any `.nim` file inside `tests/`. Verified: the compiler loads this config automatically when compiling files in `tests/`.

### `tests/tester.nim` — central test runner

Auto-discovers and runs all `tests/t*.nim` files:

```nim
import std/os

proc exec(cmd: string) =
  echo "Running: " & cmd
  if execShellCmd(cmd) != 0:
    quit "FAILURE: " & cmd, 1

let testDir = getCurrentDir() / "tests"
for f in walkFiles(testDir / "t*.nim"):
  let name = f.extractFilename
  if name == "tester.nim" or name == "thelper.nim":
    continue
  exec "nim c -r " & testDir / name

echo "All test files completed."
```

Run from the project root:

```
nim c -r tests/tester.nim
```

Adding a new test file is just creating `tests/t<name>.nim` — no runner edits needed.

### `doAssert` and `Defect` exceptions

`doAssert` raises `AssertionDefect`, which inherits from `Defect`, not `CatchableError`. Bare `except:` and `except CatchableError` do **not** catch it — the process crashes. Always catch `AssertionDefect` (or `Defect`) explicitly:

```nim
block catch_doassert:
  var raised = false
  try:
    doAssert false, "boom"
  except AssertionDefect:
    raised = true
  doAssert raised
```

This applies to any `Defect` subclass (`OverflowDefect`, `FieldDefect`, `IndexDefect`, etc.). Use the specific defect type or `except Defect` as the handler.

### Expected-failure pattern

To assert that a proc raises a specific exception, use the matching `except` type:

```nim
proc expectValueError(action: proc()) =
  var raised = false
  try:
    action()
  except ValueError:
    raised = true
  doAssert raised, "expected ValueError"

block parse_bad_input:
  expectValueError(proc() = discard parse("bad"))
```

### Test helper module (optional)

For larger test suites, extract shared helpers into `tests/thelper.nim`:

```nim
var failures* = 0
var passed* = 0

proc check*(condition: bool; msg: string) =
  if condition:
    passed += 1
  else:
    failures += 1
    echo "  FAIL: " & msg

proc summary*() =
  echo "Passed: " & $passed & "  Failed: " & $failures
  if failures > 0:
    quit "TESTS FAILED", 1
  else:
    echo "ALL TESTS PASSED"
```

Each test file imports `thelper` and calls `summary()` at the end.

## Workflow

1. **Create the project layout.** Set up `src/`, `tests/`, and `tests/config.nims` with the `--path` switch pointing to `../src`.
2. **Write test files.** Each file uses `block` for isolation and `doAssert` for assertions. Follow the `t<name>.nim` naming convention.
3. **Create the test runner.** Add `tests/tester.nim` with the auto-discover pattern above. Verify it works: `nim c -r tests/tester.nim`.
4. **Run under all configurations.** Execute the runner with each build mode:

   ```
   nim c -r tests/tester.nim                     # debug (default)
   nim c -d:release -r tests/tester.nim           # release
   nim c -d:danger -r tests/tester.nim            # danger
   ```

5. **Run with AddressSanitizer (optional).** If the project uses unsafe constructs (`ptr`, `addr`, `cstring`, manual `alloc`), run tests with ASan. See "AddressSanitizer" below.
6. **Set up CI (optional).** See `references/ci_github_actions.md` for a complete GitHub Actions workflow.

## Multi-configuration testing

| Mode                  | Command                                      | Overflow checks | Stack traces (file:line) |
|-----------------------|----------------------------------------------|-----------------|--------------------------|
| default / `-d:debug`  | `nim c -r tests/tester.nim`                  | Yes             | Full                     |
| `-d:release`          | `nim c -d:release -r tests/tester.nim`       | Yes             | Raising frame only       |
| `-d:danger`           | `nim c -d:danger -r tests/tester.nim`        | No              | Raising frame only       |

Behavioral differences to account for:

- **Overflow checks:** Disabled in `-d:danger`. Use `when defined(danger)` guards.
- **Stack traces:** Release and danger show only the raising frame. For full traces in those modes, add `--stackTrace:on --lineTrace:on`.
- **`assert` vs `doAssert`:** `doAssert` raises `AssertionDefect` in all build modes. Plain `assert` is compiled out in `-d:danger` — the statement is silently skipped. Use `doAssert` in tests so assertions always execute.

## AddressSanitizer

Detects heap-buffer-overflow, use-after-free, double-free, stack-buffer-overflow, and memory leaks.

### Linux / macOS (gcc or clang)

```
nim c \
  --passC:"-fsanitize=address -fno-omit-frame-pointer" \
  --passL:"-fsanitize=address -fno-omit-frame-pointer" \
  -g \
  -d:noSignalHandler \
  -d:useMalloc \
  -r tests/tester.nim
```

Flags explained:

- `--passC` / `--passL` — Both are required. Passes sanitizer flags to the C compiler and linker.
- `-g` (or `--debugger:native`) — Embeds debug info so ASan reports show Nim source locations.
- `-d:noSignalHandler` — Prevents Nim's signal handler from intercepting the crash, letting ASan report directly.
- `-d:useMalloc` — Makes Nim use C's `malloc` instead of its own allocator, so ASan can track every allocation.

On error, ASan prints a report with Nim file and line number:

```
==14455==ERROR: AddressSanitizer: heap-use-after-free on address 0x...
READ of size 8 at 0x... thread T0
    #0 ... in NimMainModule /tmp/.../tasan.nim:4
```

To use clang explicitly:

```
nim c --cc:clang --passC:"-fsanitize=address -fno-omit-frame-pointer" \
  --passL:"-fsanitize=address -fno-omit-frame-pointer" \
  -g -d:noSignalHandler -d:useMalloc -r tests/tester.nim
```

### Windows (MSVC)

```
nim c --cc:vcc --passC:"/fsanitize=address" -r tests/tester.nim
```

### Sanitizer config in `tests/config.nims`

To enable ASan via a define flag instead of passing all flags on the command line:

```nim
switch("path", "$projectdir/../src")

when defined(addressSanitizer):
  switch("debugger", "native")
  switch("define", "noSignalHandler")
  switch("define", "useMalloc")
  when defined(windows):
    switch("passC", "/fsanitize=address")
  else:
    switch("passC", "-fsanitize=address -fno-omit-frame-pointer")
    switch("passL", "-fsanitize=address -fno-omit-frame-pointer")
```

Then run tests with:

```
nim c -d:addressSanitizer -r tests/tester.nim
```

## Common Mistakes

| Mistake | Why it is wrong |
|---------|-----------------|
| Using `std/unittest` for simple test suites | Adds macro overhead, slower compilation, and a dependency on a framework. `block` + `doAssert` is sufficient for most Nim projects. |
| Running tests only in debug mode | `-d:release` and `-d:danger` change behavior (overflow checks, stack traces, `assert` compiled out in danger). All configurations must be tested. |
| Using `assert` instead of `doAssert` in tests | `assert` is compiled out in `-d:danger`, so a failing test silently passes. `doAssert` always executes. |
| Using bare `except:` or `except CatchableError` to catch `doAssert` failures | `AssertionDefect` inherits from `Defect`, not `CatchableError`. Bare `except:` and `except CatchableError` do not catch it. Use `except AssertionDefect` or `except Defect`. |
| Relying on `OverflowDefect` without a `when defined(danger)` guard | The exception is never raised in danger mode; the test silently passes or fails differently. |
| Running ASan without `-d:useMalloc` | Nim's default allocator may not be fully intercepted by ASan, causing false negatives. |
| Running ASan without `-d:noSignalHandler` | Nim's signal handler intercepts SIGSEGV before ASan can report. The ASan report will not appear. |
| Using only `--passC` without `--passL` for ASan | The sanitizer runtime must be linked. Both flags are required. |
| Putting `config.nims` at project root instead of `tests/` | The path resolution (`$projectdir/../src`) is relative to the test file's directory. A root config does not affect test compilation unless tests import it explicitly. |

## References

- `references/block_test_pattern.md` — Full worked example: project layout, test files, helper module, and auto-discovering runner
- `references/ci_github_actions.md` — Complete GitHub Actions CI workflow for Linux, macOS, and Windows

## Changelog

- 2026-04-20: Created. All commands validated on Nim 2.3.1 / gcc 15 / Linux.
- 2026-04-20: Removed incorrect claim that `doAssert` is compiled out in `-d:danger`. Verified that `doAssert` raises `AssertionDefect` in all build modes on Nim 2.3.1. Added `assert` vs `doAssert` distinction: `assert` is compiled out in `-d:danger` only; `doAssert` always executes.
- 2026-04-20: Added `Defect` exception handling guidance. `AssertionDefect` is not caught by bare `except:` or `except CatchableError`. Must use `except AssertionDefect`, `except Defect`, or `except Exception`.
