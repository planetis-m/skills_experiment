# Benchmark Task: Nim C Bindings — Local Shared Library Wrapper

## Task

Write a Nim program that wraps a small vendored C math library, links against it correctly, and runs assertions at runtime.

### Step 1 — Create the C library

Create `third_party/mathlib/src/mathlib.c`:

```c
#include "mathlib.h"

int mathlib_add(int a, int b) { return a + b; }
int mathlib_mul(int a, int b) { return a * b; }
```

Create `third_party/mathlib/src/mathlib.h`:

```c
#ifndef MATHLIB_H
#define MATHLIB_H
int mathlib_add(int a, int b);
int mathlib_mul(int a, int b);
#endif
```

### Step 2 — Build the shared library

```bash
mkdir -p third_party/mathlib/lib
gcc -shared -fPIC -o third_party/mathlib/lib/libmathlib.so third_party/mathlib/src/mathlib.c
```

### Step 3 — Write `subject_solution.nim`

Write a Nim program that:

1. Declares bindings for `mathlib_add` and `mathlib_mul` using `importc` with the correct calling convention and `header` pragma.
2. Asserts:
   - `mathlib_add(3, 4) == 7`
   - `mathlib_mul(5, 6) == 30`
   - `mathlib_add(-1, 1) == 0`
3. Prints "All tests passed" on success.

### Step 4 — Compile and run

```bash
nim c --mm:orc \
  --passC:"-Ithird_party/mathlib/src" \
  --passL:"-Lthird_party/mathlib/lib -lmathlib" \
  --passL:"-Wl,-rpath,'\$ORIGIN'" \
  -o:./app subject_solution.nim

cp third_party/mathlib/lib/libmathlib.so ./
./app
```

The program should exit with code 0, print "All tests passed", and the binary's RUNPATH must contain `$ORIGIN`.

## Constraints

- Use `importc` with `cdecl` calling convention.
- Use the `header` pragma pointing at `"mathlib.h"`.
- The `-L` path must be repository-relative (not absolute).
- The rpath must be `$ORIGIN`, not an absolute path.
- The `.so` must be colocated next to the executable for runtime resolution.
- Do not set `LD_LIBRARY_PATH` or any other environment variable.
- Do not use `dynlib` pragma.

## Deliverable

A `subject_solution.nim` file that compiles and passes all assertions when built and run as described above.

## Scoring Checklist

| # | Check | Binary (Y/N) |
|---|-------|-------------|
| 1 | Compilation succeeds with the exact command above | Y/N |
| 2 | `mathlib_add` and `mathlib_mul` are declared with `importc` pragma | Y/N |
| 3 | Both procs use `cdecl` calling convention (explicit or via push block) | Y/N |
| 4 | `header` pragma is present on the bindings | Y/N |
| 5 | Runtime execution prints "All tests passed" (exit code 0) | Y/N |
| 6 | No `LD_LIBRARY_PATH` or environment variable is set for runtime | Y/N |
| 7 | No `dynlib` pragma is used | Y/N |
| 8 | `-L` path is relative (not absolute) | Y/N |
| 9 | Binary RUNPATH contains `$ORIGIN` (no absolute build-tree path) | Y/N |
| 10 | The `.so` is colocated next to the executable | Y/N |
