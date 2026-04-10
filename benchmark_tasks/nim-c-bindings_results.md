# Benchmark Results — nim-c-bindings

## Task Summary

Write Nim bindings for a vendored C shared library (mathlib), link with repository-relative paths and `$ORIGIN` rpath, colocate the `.so`, and pass runtime assertions.

## Scoring Checklist

| # | Check | Binary |
|---|-------|--------|
| 1 | Compilation succeeds with the exact command | Y/N |
| 2 | `importc` pragma on bindings | Y/N |
| 3 | `cdecl` calling convention | Y/N |
| 4 | `header` pragma present | Y/N |
| 5 | Prints "All tests passed", exit 0 | Y/N |
| 6 | No `LD_LIBRARY_PATH` set | Y/N |
| 7 | No `dynlib` pragma | Y/N |
| 8 | `-L` path is relative | Y/N |
| 9 | RUNPATH contains `$ORIGIN` (no absolute path) | Y/N |
| 10 | `.so` colocated next to executable | Y/N |

## Validation Status

Locally validated on Linux x86_64 with Nim 2.3.1, gcc, `--mm:orc`. Reference solution compiles and passes all 10 checklist items.

## Ceiling Risk

Moderate. The task is well-specified (exact C code, exact compile command) but still requires the agent to write correct `importc` bindings with the right pragmas, and the checklist catches specific anti-patterns (dynlib, absolute paths, missing rpath). No-skill agents should still succeed on the basic binding but may miss rpath/colocation/linking details.

## Run Shape

`original`, `verified`, `no-skill`; `NUM_TRIALS=3`; `ORCHESTRATOR_TIMEOUT_MINUTES=27`
