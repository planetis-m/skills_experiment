---
name: nim-doc-comments
description: Write Nim doc comments in the standard source layout and verify rendered docs with `nim doc`.
---

# Nim Doc Comments

Rules and workflow for writing doc comments that render correctly with `nim doc`.

Larger examples live in `references/`.

## Rules

### Placement

- Module docs go at the top of the file, before imports and declarations. Use `##` lines or `##[ ... ]##` block syntax.
- Proc/func/iterator/template/converter docs go immediately after the signature line, before the body.
- Inside `type`, `const`, and `let` blocks, attach docs to the declaration line with an inline trailing `##`.
- For multi-line docs on a declaration, continue with indented `##` lines aligned under it.
- Enum value and object field docs go on the same line when short; use continuation `##` lines only when needed.
- Do not put a standalone `##` line above a declaration inside a `type` or `const` block and expect it to attach to that symbol.

### Visibility

- Only exported symbols (`*`) appear in rendered docs. Non-exported symbols are hidden.
- Document exported symbols first.

### runnableExamples

- Do not add `runnableExamples:` by default. Add them only when requested or when the surrounding codebase already uses them.
- Place `runnableExamples:` after doc text, before implementation statements.
- Top-level `runnableExamples:` (after module docs) also works.
- Use `runnableExamples("-d:flag")` to pass compile flags to the example.
- `nim doc` compiles and runs all `runnableExamples:` blocks. A failing assertion causes `nim doc` to fail.

### Content

- Start with a short summary sentence. Explain behavior, contracts, and constraints.
- Skip comments that only restate the symbol name or obvious type info.
- Use `See also` only when a genuinely related API exists.

## Workflow

1. Identify the exported symbols that form the public API.
2. Add or improve doc comments following the placement rules above.
3. Add `runnableExamples:` only if requested or clearly established in the codebase.
4. Run `nim doc path/to/module.nim` to render the docs.
5. Check both the source placement and the HTML output for structure, grouping, and readability.
6. Fix the source comments — never edit generated output.

## Common Mistakes

| Mistake | Why it's wrong |
|---------|---------------|
| Putting a proc doc comment above the proc signature | `nim doc` treats it as module documentation instead of attaching it to the proc. |
| Putting a standalone `##` line above a type declaration inside a `type` block | It does not attach to that type in rendered docs; use declaration-attached docs on the declaration line. |
| Putting a standalone `##` line above a const declaration inside a `const` block | It does not attach to that const in rendered docs; use declaration-attached docs on the declaration line. |
| Assuming rendered HTML alone proves correct module-doc placement | A module-style `##` comment after imports can still render as module documentation, so check source placement too. |

## References

- `references/module_docs.md` — Module doc patterns (line and block syntax)
- `references/proc_and_type_docs.md` — Proc, type, enum, const, and field doc placement
- `references/runnable_examples.md` — runnableExamples placement and parameterized flags

## Changelog

- 2026-04-09: Verified skill created from 14 empirically tested claims (all passing on Nim 2.3.1/ORC).
- 2026-04-09: Added empirically verified wrong-placement cases for proc docs above signatures and standalone docs above declarations inside `type`/`const` blocks.
