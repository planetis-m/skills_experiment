---
name: nimonyplugins
description: Write correct Nimony plugins against the actual installed `nimonyplugins.nim` API, with clear `Tree`/`Node` usage and safe traversal and construction patterns.
---

# Nimony Plugins

Rules for writing plugins using the `nimonyplugins` API. Resolve the actual API source before writing any plugin code.

## Rules

### Setup

1. Resolve the nimony executable: `readlink -f "$(command -v nimony)"`. If it's `.../bin/nimony`, open `../src/nimony/lib/nimonyplugins.nim` from there.
2. Compile with `--path:` pointing to nimony's `src/` directory.

### Mental Model

3. `Tree` is the mutable copy-on-write builder. Copying a Tree shares the payload; the next mutation detaches it. Do not assume a copied Tree sees later mutations from another copy.
4. `Node` is an owned read handle into a frozen snapshot. Copying a Node creates another read handle to the same snapshot. A Node keeps its backing tree alive.
5. `snapshot(tree)` requires a non-empty tree. Guard with `isEmpty(tree)` first.
6. Treat `Tree` as owned mutable output. Treat `Node` as a stable read cursor.

### Construction

7. `createTree()` creates an empty tree. `createTree(kind, children...)` and `createTree(kind, info, children...)` build a validated node in one call.
8. `withTree(kind, info): body` is the primary way to emit balanced nodes: opens tag, runs body, closes tag. Use manual `addParLe`/`addParRi` only when conditional structure makes `withTree` awkward.
9. Constructed trees are validated. Emit balanced trees matching expected child categories for each tag.
10. Use `NoLineInfo` only for genuinely synthetic structure. Preserve source `info` from existing nodes when output is derived from them.
11. `~` converts values to Tree fragments: `~"str"` → string literal, `~42` → int lit, `~true` → bool, `~'c'` → char, `~ident("name")` → identifier, `~node` → subtree copy, `~tree` → identity.
12. `nifFragment("(call echo \"hello\")")` parses literal NIF text into a Tree.
13. `%~` parses a NIF template with `$name` substitutions.

### Traversal

14. `inc(node)` advances one token. `skip(node)` skips the whole current subtree. Do not use `inc` when you mean `skip` — the representation is token-based, not heap-linked.
15. Copy a Node for lookahead without committing movement on the original.
16. `kind`, `stmtKind`, `exprKind`, `typeKind`, `otherKind`, `pragmaKind` inspect the current node category.
17. `symId`, `symText`, `identText`, `stringValue`, `charLit`, `intValue`, `uintValue`, `floatValue` read the current token payload.
18. `tagId`, `tagText`, `tag` inspect raw NIF tags.
19. `eqIdent(name)` checks exact identifier/symbol name match.

### Subtree Operations

20. `takeTree(t, var node)` copies the current subtree into `t` and **advances** the reader.
21. `addSubtree(t, node)` copies the current subtree into `t` **without** advancing the reader.
22. `add(t, childTree)` appends a complete Tree.

### Literals and Placeholders

23. `addDotToken`, `addStrLit`, `addIntLit`, `addUIntLit`, `addIdent`, `addCharLit`, `addFloatLit` emit atoms.
24. `addSymUse(symId|string, info)` emits a symbol-use token.
25. `addEmptyNode` through `addEmptyNode4` emit one to four dot placeholders.

### Errors and IO

26. `errorTree(msg)` for synthetic errors. `errorTree(msg, at)` with source location. `errorTree(msg, at, orig)` with location and embedded source.
27. `renderTree(tree)` and `renderNode(node)` for debugging (omits line info).
28. `isValid(info)`, `filePath(info)`, `lineCol(info)` for source location inspection.
29. `loadPluginInput()` reads `paramStr(1)`, returns root Node. `saveTree(tree)` writes to `paramStr(2)`.

## Workflow

1. **Locate API.** Resolve nimony executable, open `nimonyplugins.nim`.
2. **Load input.** `loadPluginInput()` → root `Node`.
3. **Traverse.** One primary `var Node`. Copy for lookahead when needed.
4. **Build output.** Fresh `Tree`. Use `withTree` for balanced nodes.
5. **Preserve structure.** `takeTree` or `addSubtree` for existing subtrees unless a rewrite is needed.
6. **Handle errors.** `errorTree` for invalid cases.
7. **Save.** `saveTree(result)`.

## Common Mistakes

| Mistake | Why it's wrong |
|---------|----------------|
| Confusing `takeTree` with `addSubtree` | `takeTree` advances the reader, `addSubtree` does not. Wrong choice desynchronizes traversal. |
| Using `inc` instead of `skip` on subtrees | `inc` moves one token; `skip` moves past the whole subtree. Using `inc` on a node with children leaves you inside it. |
| Assuming copied Trees share mutations | Tree is COW — mutation detaches. A copied Tree does not see later writes through another copy. |
| Snapshotting an empty tree | Triggers assertion. Guard with `isEmpty` first. |
| Rebuilding existing subtrees token-by-token | Use `takeTree`/`addSubtree` to preserve correct subtrees instead of reconstructing them. |
| Emitting malformed node shapes | Constructed trees are validated; bad shapes produce `ErrT` or assertion failures. |

## References

No separate reference files. All patterns are inline in the skill.

## Changelog

- 2026-04-09: Initial verified skill created from original `nimonyplugins` with 33 claims extracted, 13 positive tests passing on Nim 2.3.1/ORC with nimony 0.2.0. No corrections needed.
