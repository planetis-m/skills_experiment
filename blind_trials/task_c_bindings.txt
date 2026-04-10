# Task: Write raw Nim bindings for one vendored shared library plus one system C symbol

Create a file called `subject_solution.nim`.

This is a raw FFI task, not a wrapper-design task. Keep the exported surface close to the C API.
The benchmark is Linux-only in this repo.

## Provided fixture

The repo already contains:

- `blind_trials/c_bindings_fixture/benchffi.h`
- `blind_trials/c_bindings_fixture/benchffi.c`

The benchmark runner will build the helper shared library from that source before compiling your Nim file.

## Required public surface

Export these exact types, constants, and procs:

```nim
type
  BenchHandleObj = object
  BenchHandle* = ptr BenchHandleObj

  BenchConfig* {.bycopy.} = object
    bias*: cint
    scale*: cuint
    label*: cstring

  BenchSnapshot* {.bycopy.} = object
    count*: csize_t
    total*: clonglong
    mean*: cdouble
    checksum*: culong

  BenchStatus* {.bycopy.} = object
    code*: cint
    message*: cstring

const
  BENCHFFI_STATUS_OK* = 0.cint
  BENCHFFI_STATUS_INVALID_ARGUMENT* = 1.cint

proc benchffi_open*(config: ptr BenchConfig): BenchHandle
proc benchffi_close*(handle: BenchHandle)
proc benchffi_push_i32*(handle: BenchHandle; values: ptr cint; len: csize_t): BenchStatus
proc benchffi_snapshot_read*(handle: BenchHandle): BenchSnapshot
proc benchffi_label*(handle: BenchHandle): cstring

proc c_cos*(x: cdouble): cdouble
```

`c_cos` must bind the real C `cos` symbol from `<math.h>`.

## Critical binding requirements

- Keep this as a raw binding surface. Do not add an ergonomic wrapper API on top.
- Use `importc` with `cdecl`.
- Use one shared pragma block for the `benchffi.h` declarations.
- Keep the handle opaque. Do not declare the C struct layout in Nim.
- Use repository-relative local link flags for the vendored helper library.
- Link the system math library with `-lm` only. Do not hardcode `/usr/lib`, `/lib64`, or other system `-L` paths.
- On Linux, use `$ORIGIN` rpath for the local helper library. Do not embed an absolute or build-tree runtime path.
- Do not rely on `LD_LIBRARY_PATH`, `DYLD_LIBRARY_PATH`, or `PATH` for runtime discovery.

## Required smoke run

Add a `when isMainModule:` block that:

1. Builds this config:

```nim
var config = BenchConfig(
  bias: 2,
  scale: 3,
  label: "alpha"
)
```

2. Opens the handle and asserts it is non-nil.
3. Pushes these values:

```nim
let values = [1.cint, 4.cint, 7.cint]
```

4. Asserts:

- `benchffi_push_i32` returns `code == BENCHFFI_STATUS_OK`
- `benchffi_push_i32(...).message == "ok"`
- `benchffi_snapshot_read(handle).count == 3`
- `benchffi_snapshot_read(handle).total == 54`
- `abs(benchffi_snapshot_read(handle).mean - 18.0) < 1e-12`
- `benchffi_snapshot_read(handle).checksum == 156834`
- `benchffi_label(handle) == "alpha"`
- `abs(c_cos(0.0) - 1.0) < 1e-12`

5. Closes the handle exactly once.
6. Prints:

```nim
echo "SMOKE: PASS"
```

## Required build and run

Your `subject_solution.nim` must compile and run with these commands from the repo root:

```bash
mkdir -p blind_trials/c_bindings_fixture/build blind_trials/c_bindings_fixture/run
cc -shared -fPIC blind_trials/c_bindings_fixture/benchffi.c \
  -Iblind_trials/c_bindings_fixture \
  -o blind_trials/c_bindings_fixture/build/libbenchffi.so
nim c --mm:orc --out:blind_trials/c_bindings_fixture/build/subject_solution subject_solution.nim
cp blind_trials/c_bindings_fixture/build/subject_solution blind_trials/c_bindings_fixture/run/
cp blind_trials/c_bindings_fixture/build/libbenchffi.so blind_trials/c_bindings_fixture/run/
blind_trials/c_bindings_fixture/run/subject_solution
```

## Judge checklist

Score only these checks:

- compiles with the required commands above
- the relocated runtime step prints `SMOKE: PASS`
- the exported surface contains the exact required types, constants, and procs
- `BenchHandle` is an opaque pointer type rather than a declared full C struct layout
- `BenchConfig`, `BenchSnapshot`, and `BenchStatus` are `bycopy` objects matching the header field order
- the `benchffi.h` imports share one `cdecl` + `header` pragma block
- the source contains repo-relative local link flags for `libbenchffi`
- the source contains Linux `$ORIGIN` rpath for the vendored shared library
- the source links the system math library with `-lm` only and does not add a system-library `-L` path
- the source does not mention `LD_LIBRARY_PATH`, `DYLD_LIBRARY_PATH`, or `PATH` as the runtime solution
- the file stays a raw binding layer instead of adding a friendly wrapper API

After writing, verify it with the required build and run commands.
