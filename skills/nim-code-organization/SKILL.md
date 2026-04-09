---
name: nim-code-organization
description: Organize Nim modules and orchestration code with clear state ownership and intentional exports.
---

# Nim Code Organization

Rules for structuring modules, orchestration flows, helper placement, and export surfaces in Nim.

Larger examples live in `references/`.

## Rules

### State and helpers

- Prefer explicit state objects and top-level helper procs with `var State` parameters over nested procs that capture mutable outer locals.
- Nested closures capturing mutable locals compile and run correctly under ORC, but they make data flow harder to follow. Use them only when the closure is short and the capture is obvious.
- For multi-step orchestration, define a state type and pass it explicitly through helper procs.

### Imports and exports

- Remove unused imports immediately — Nim warns about them (`UnusedImport`).
- Only exported symbols (`*`) are accessible from other modules. Non-exported symbols are private.
- Keep exports intentional. Do not export internals by default.

### Dead code

- Remove dead declarations and unused imports as soon as they are noticed.

## Workflow

1. Identify the orchestration flow and its mutable state.
2. Define an explicit state object if helpers need to share mutable data.
3. Write helper procs as top-level procs taking `var State` (or the relevant parameters).
4. Verify imports are used and exports are intentional.
5. Remove any dead code introduced during the refactor.

## Common Mistakes

| Mistake | Why it's wrong |
|---------|---------------|
| Nesting a proc inside another proc to capture mutable locals | Makes data flow implicit and harder to reason about; prefer explicit parameters. |
| Exporting symbols by default | Leaks internals; export only what other modules need. |
| Leaving unused imports | Triggers compiler warnings and adds noise. |

## References

- `references/orchestration_pattern.md` — Explicit state vs nested closure comparison

## Changelog

- 2026-04-09: Verified skill created from 6 claims. 1 correction: nested closures under ORC are a design preference, not a correctness hazard.
