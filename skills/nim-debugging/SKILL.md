---
name: nim-debugging
description: Debug Nim programs using echo-based inspection, stack traces, compiler expansion flags, and runtime memory sanitizers. Use when diagnosing runtime crashes, unexpected behavior, memory errors, macro output, or ARC/ownership issues in Nim code.
---

# Nim Debugging

Practical techniques for debugging Nim programs. Covers echo-based inspection, stack traces, compiler expansion flags, memory sanitizer configuration, and ARC/ownership debugging. All guidance has been verified on Nim 2.3.1 with gcc 15 and clang 21 on Linux.

Extended examples live in `references/`.

## Rules

### Build modes and stack traces

The default build mode is **debug** (no `-d:` flag needed). The compiler output confirms this: `opt: none (DEBUG BUILD, '-d:release' generates faster code)`.

| Build mode            | Opt level | Stack traces with line numbers | `writeStackTrace()` output |
|-----------------------|-----------|-------------------------------|---------------------------|
| default / `-d:debug`  | none      | Full: file path + line number | Full with file paths and line numbers |
| `-d:release`          | speed     | Only the raising frame (no full trace) | `No stack traceback available` |
| `-d:danger`           | speed     | Only the raising frame (no full trace) | `No stack traceback available` |

To get full stack traces in release or danger mode, add both flags:

```
--stackTrace:on --lineTrace:on
```

This restores full file-and-line-number stack traces at the cost of some optimization. `--lineTrace:on` implies `--stackTrace:on` but using both is explicit and safe.

`--excessiveStackTrace:on` (the default) shows full file paths. `--excessiveStackTrace:off` shows only filenames.

### Echo-based debugging

Use `echo` to inspect values at any point. For types without a `$` operator, use `repr`:

```nim
echo "x = ", x
echo "r = ", repr(r)      # works on any type
```

`repr` output examples (verified):
- `MyRef(x: 42, s: "hello")` for ref objects
- `@[1, 2, 3]` for sequences
- `"world"` for strings
- `00007FE33AB7B040` for raw pointers

Inside `{.noSideEffect.}` procs, use `debugEcho` instead of `echo` — it compiles where `echo` would be rejected.

### `writeStackTrace()`

Call `writeStackTrace()` at any point to print the current call stack. Works in default and `-d:debug` modes. Returns `No stack traceback available` in `-d:release` and `-d:danger` unless you compile with `--stackTrace:on --lineTrace:on`.

### Macro debugging: `--expandMacro`

Show the AST a macro produces:

```
nim c --expandMacro:<macro_name> <file.nim>
```

The compiler prints a hint like:
```
file.nim(9, 10) Hint: expanded macro: echo(["value is: ", x]) [ExpandMacro]
```

Multiple `--expandMacro` flags can be combined in one invocation. The flag works with any build mode or memory manager.

### ARC/ownership debugging: `--expandArc`

Show how a proc is rewritten after ARC/ORC ownership analysis:

```
nim c --expandArc:<proc_name> <file.nim>
```

The output shows injected `=copy`, `=destroy`, `=sink`, and `move` calls. The target proc must be reachable from the program entry point; uncalled procs are skipped by the analysis. Works with all three supported memory managers (`--mm:orc`, `--mm:arc`, `--mm:atomicArc`). The output is the same across all three for simple ownership patterns; differences appear in cyclic-reference handling (ORC only).

See `references/arc_optimization.md` for a worked example showing copy vs move.

### Memory management modes

The three supported modes are:

| Flag              | Behavior                                         |
|-------------------|--------------------------------------------------|
| `--mm:orc`        | Default. Cycle-collecting reference counting.    |
| `--mm:arc`        | Reference counting without cycle collection.     |
| `--mm:atomicArc`  | Same as `arc` with atomic reference counting.    |

`--expandArc` output is applicable under all three. When debugging ownership issues, test under the same `--mm:` mode your project uses.

### Debug info for native debuggers

Use `--debugger:native` to embed DWARF debug info (line numbers, variable names) in the binary. This is equivalent to `--debuginfo --linedir:on`.

Do not use `gdb`. Use AddressSanitizer or Valgrind instead (see below).

### Runtime memory diagnostics

Use these when working with unsafe constructs: `addr`, `ptr T`, `cstring`, `cstringArray`, manual `alloc`/`dealloc`, or C FFI.

#### AddressSanitizer (primary)

Detects heap-buffer-overflow, use-after-free, double-free, stack-buffer-overflow, and memory leaks.

**Linux/macOS (gcc or clang):**

```
nim c \
  --passC:"-fsanitize=address -fno-omit-frame-pointer" \
  --passL:"-fsanitize=address -fno-omit-frame-pointer" \
  -g \
  -d:noSignalHandler \
  -d:useMalloc \
  <file.nim>
```

Flags explained:
- `--passC` / `--passL`: Both are required. Passes the sanitizer flags to the C compiler and linker.
- `-g` (or `--debugger:native`): Embeds debug info so ASan reports show Nim source locations.
- `-d:noSignalHandler`: Prevents Nim's signal handler from intercepting the crash, letting ASan report directly.
- `-d:useMalloc`: Makes Nim use C's `malloc` instead of its own allocator, so ASan can track every allocation. Only works with `--mm:arc` or `--mm:orc`.

Run the binary normally. On error, ASan prints a detailed report with Nim file/line:

```
==14455==ERROR: AddressSanitizer: heap-buffer-overflow on address 0x...
READ of size 8 at 0x... thread T0
    #0 ... in test_asan_oom::main /tmp/.../test_asan_oom.nim:8
```

**To use clang explicitly:**

```
nim c --cc:clang --passC:"-fsanitize=address -fno-omit-frame-pointer" ...
```

Clang's ASan requires `llvm-symbolizer` in `$PATH` to resolve symbols and show Nim source file/line in the report. Without it, frames show raw hex addresses. Install it via the LLVM toolchain package for your distro (e.g. `dnf install llvm` on Fedora, `apt install llvm` on Debian/Ubuntu). gcc's ASan resolves symbols natively and does not need a separate symbolizer.

**Windows (MSVC):**

```
nim c --cc:vcc --passC:"/fsanitize=address" <file.nim>
```

#### Valgrind (secondary)

Use when ASan is unavailable or unsuitable. Does not require special compilation flags.

```
nim c -o:<binary> <file.nim>
valgrind --leak-check=full --error-exitcode=1 ./<binary>
```

Valgrind detects memory leaks, use-after-free, and uninitialized reads. It is slower than ASan and does not require `-d:useMalloc`. Compile with `-g` for source-level annotations.

#### Environment setup

Before using sanitizers, verify the toolchain:

```bash
gcc -v 2>&1 | head -1       # or clang -v
echo "int main(){return 0;}" | gcc -fsanitize=address -x c - -o /dev/null 2>&1
```

If the sanitizer flag is not recognized, install the toolchain:
- Fedora/RHEL: `dnf install gcc gcc-plugin-annobin` (gcc includes ASan support by default)
- Ubuntu/Debian: `apt install gcc`
- macOS: Xcode Command Line Tools include ASan support in clang
- Windows: Visual Studio 2019+ with the "C++ AddressSanitizer" workload

If installation is not possible, report a clear error — do not silently skip sanitizer testing.

## Workflow

1. **Reproduce the issue.** Build in default mode (debug). Confirm the error is reproducible.
2. **Read the stack trace.** Default builds show full file paths and line numbers. If the trace is missing, see "Build modes and stack traces" above.
3. **Add echo inspection.** Insert `echo` or `debugEcho` calls at the suspect point. Use `repr` for complex types.
4. **If the issue is in a macro**, run `nim c --expandMacro:<name>` and inspect the expanded AST.
5. **If the issue involves ownership or copies**, run `nim c --expandArc:<proc>` under the project's `--mm:` mode. Compare the output to expected copy/move/destroy behavior.
6. **If the issue involves unsafe memory** (`ptr`, `addr`, `cstring`, manual alloc), rebuild with AddressSanitizer flags and run. If ASan is unavailable, use Valgrind.
7. **If the issue only appears in release/danger builds**, rebuild with `--stackTrace:on --lineTrace:on` plus the release/danger flag to get traces. Check whether optimization changed behavior.
8. **Verify the fix.** Remove debug prints. Run under ASan if memory was involved. Run under all relevant `--mm:` modes if ownership was involved.

## Common Mistakes

| Mistake | Why it is wrong |
|---------|-----------------|
| Using `-d:release` and expecting full stack traces | Release disables line tracing. Add `--stackTrace:on --lineTrace:on`. |
| Running ASan without `-d:useMalloc` | Nim's default allocator may not be fully intercepted by ASan. `-d:useMalloc` ensures every allocation goes through `malloc`. |
| Running ASan without `-d:noSignalHandler` | Nim's signal handler intercepts SIGSEGV before ASan can report. The ASan report will not appear. |
| Using only `--passC` without `--passL` for ASan | The sanitizer runtime must be linked. Both flags are required. |
| Using `echo` inside `{.noSideEffect.}` procs | Won't compile. Use `debugEcho`. |
| Using clang ASan without `llvm-symbolizer` | ASan detects the error but shows raw hex addresses instead of Nim source locations. Install `llvm-symbolizer` or use gcc instead. |
| Using `gdb` | Not recommended. Name mangling makes variable inspection unreliable. Use ASan or echo-based debugging. |
| Assuming `-d:debug` changes behavior vs default | It doesn't. Default is already debug mode. `-d:debug` is a no-op identity. |

## References

- `references/arc_optimization.md` — Worked example: identifying and fixing an unnecessary copy using `--expandArc`

## Changelog
- 2026-04-20: Created and refined.
- 2026-04-20: Added clang llvm-symbolizer requirement.
