# Phase 2 Prompt: Empirical Verification

For every testable claim in `nim-ownership-hooks_dataset.json`:

1. Create directory `tests/nim-ownership-hooks_verification/` if it doesn't exist.

2. Write a minimal, reproducible Nim test program for each claim. Each test must:
   - Compile with `nim c --mm:orc`
   - Print "PASS" on success
   - For negative tests (expected compile errors): write the file but do NOT try to run it

3. Guidelines for test programs:
   - Use `ptr T` with `alloc`/`dealloc` for raw pointer tests
   - Use `var` counters to track hook calls
   - Include both positive (happy path) and boundary cases
   - For claims about compile errors, create a separate file that should FAIL to compile

4. Execute all positive tests: `nim r --mm:orc <test_file>`
5. Execute all negative tests: `nim c --mm:orc <test_file>` and verify the compiler reports an error.

6. Update `nim-ownership-hooks_dataset.json` with:
   - `test_file_path`: path to the test file
   - `test_passed`: boolean
   - `compiler_output`: relevant output
   - `evaluation_notes`: did the claim hold? edge cases?

Tool requirement: `nim` compiler version 2.3.1+, `--mm:orc` mode.
