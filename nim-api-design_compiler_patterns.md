# Nim Compiler API Design Patterns

Extracted from the Nim compiler source at `~/Projects/Nim/compiler/`.
This document catalogs API design patterns found in a large, production Nim codebase,
with recommendations for a "Nim API Design" skill.

---

## 1. Contracts: Type Constraints, Calling Conventions, Pragmas

### 1.1 `{.nimcall.}` / `{.closure.}` on Callback Proc Types
**Files:** `ast.nim:49-52`, `modulegraphs.nim:108-120,134-135`

The compiler consistently annotates callback/function-pointer fields with explicit
calling conventions. This is critical for any library exposing function pointer slots.

```nim
# ast.nim:49-52
proc loadSymCallback*(s: PSym) {.nimcall.} =
  loadSym(s)

# modulegraphs.nim:108-109
importModuleCallback*: proc (graph: ModuleGraph; m: PSym, fileIdx: FileIndex): PSym {.nimcall.}
includeFileCallback*: proc (graph: ModuleGraph; m: PSym, fileIdx: FileIndex): PNode {.nimcall.}

# modulegraphs.nim:134-135 — pass system uses nimcall procs
TPassOpen* = proc (graph: ModuleGraph; module: PSym; idgen: IdGenerator): PPassContext {.nimcall.}
TPassClose* = proc (graph: ModuleGraph; p: PPassContext, n: PNode): PNode {.nimcall.}
```

**Verdict: ✅ Good pattern.** Always annotate calling conventions on proc-type fields and callbacks. Use `nimcall` for internal callbacks (fastest), `closure` when you need captured state, `cdecl` for C interop.

### 1.2 Minimal Use of `{.raises.}` / `{.tags.}`
**File:** Throughout compiler source

The compiler itself barely uses `{.raises.}` or `{.tags.}` annotations on its own procs. Instead, it relies on `{.gcsafe.}` in a few places (e.g., `docgen.nim:243,279,286`). The effect system is *implemented* by the compiler but not heavily consumed internally.

**Verdict: ⚠️ Mixed.** For library APIs, `{.raises.}` and `{.gcsafe.}` are valuable contracts. The compiler's avoidance is partly pragmatic (legacy codebase, effect inference handles most cases). Recommend using them on public APIs where exception safety matters.

### 1.3 `{.inline.}` for Trivial Accessors
**File:** `ast.nim:55-340` (hundreds of accessors)

Every field accessor in the compiler is marked `{.inline.}`:

```nim
proc kind*(s: PSym): TSymKind {.inline.} =
  if s.state == Partial: loadSym(s)
  result = s.kindImpl

proc `kind=`*(s: PSym, val: TSymKind) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadSym(s)
  s.kindImpl = val
```

**Verdict: ✅ Good pattern.** Mark trivial property-like accessors as `{.inline.}`. The compiler does this uniformly for all ~80+ accessor pairs, which is appropriate given they contain at most 3 lines of logic.

---

## 2. Result and Error Handling Patterns

### 2.1 Error Reporting via `ConfigRef` + `TLineInfo` (Side-Channel Errors)
**File:** `msgs.nim:627-665`

The compiler uses a *side-channel* error reporting model. Procs don't return `Result` types — instead they call `localError`/`globalError`/`internalError`/`fatal` templates that write to `ConfigRef` and set counters. Compilation continues until `errorMax` is reached.

```nim
# msgs.nim:635-638
template localError*(conf: ConfigRef; info: TLineInfo, msg: TMsgKind, arg = "") =
  liMessage(conf, info, msg, arg, doNothing, instLoc())

template localError*(conf: ConfigRef; info: TLineInfo, arg: string) =
  liMessage(conf, info, errGenerated, arg, doNothing, instLoc())

# msgs.nim:627-632
template globalError*(conf: ConfigRef; info: TLineInfo, msg: TMsgKind, arg = "") =
  liMessage(conf, info, msg, arg, doRaise, instLoc())

template globalError*(conf: ConfigRef; info: TLineInfo, arg: string) =
  liMessage(conf, info, errGenerated, arg, doRaise, instLoc())
```

The three-tier hierarchy:
- `localError`: report but keep going (error recovery)
- `globalError`: raise a `RecoverableError` exception
- `fatal` / `internalError`: abort immediately

**Verdict: ⚠️ Domain-specific.** This pattern makes sense for a compiler where you want to report *all* errors in one pass. For general libraries, prefer `Result[T, E]` or `Option[T]` as return values. The side-channel approach couples everything to a `ConfigRef` context object.

### 2.2 nkError Nodes for Structured Error Propagation
**File:** `errorhandling.nim:1-85`

A newer, more structured approach embeds errors directly in the AST:

```nim
type
  ErrorKind* = enum
    RawTypeMismatchError
    ExpressionCannotBeCalled
    CustomError
    WrongNumberOfArguments
    AmbiguousCall

proc newError*(wrongNode: PNode; k: ErrorKind; args: varargs[PNode]): PNode =
  let innerError = errorSubNode(wrongNode)
  if innerError != nil:
    return innerError
  result = newNodeIT(nkError, wrongNode.info, newType(tyError, idgen, nil))
  result.add wrongNode
  result.add newIntNode(nkIntLit, ord(k))
  for a in args: result.add a
```

**Verdict: ✅ Good pattern.** This is effectively a typed error union — the error is part of the data structure. The `errorSubNode` helper checks for inner errors first (error deduplication). This pattern works well when you need to propagate errors through a processing pipeline without exceptions.

### 2.3 Boolean Return + Var Parameter for Errors
**File:** `types.nim` (various), `astdef.nim` (strTableIncl)

```nim
# astdef.nim — strTableIncl returns bool for conflict detection
proc strTableIncl*(t: var TStrTable, n: PSym;
                   onConflictKeepOld = false): bool {.discardable.} =
  result = strTableInclReportConflict(t, n, onConflictKeepOld) != nil
```

**Verdict: ✅ Good pattern.** Using `bool` return + `var` out-params or separate query procs is idiomatic Nim. The `{.discardable.}` pragma lets callers ignore the result when they don't care about conflicts.

### 2.4 `getOrdValueAux` — Var Bool Error Flag
**File:** `types.nim:94-113`

```nim
proc getOrdValueAux*(n: PNode, err: var bool): Int128 =
  # ...
  of nkNilLit:
    int128.Zero
  else:
    err = true
    int128.Zero

proc getOrdValue*(n: PNode): Int128 =
  var err: bool = false
  result = getOrdValueAux(n, err)
  # silently ignores error
```

**Verdict: ⚠️ Anti-pattern to avoid.** Using a `var bool` error flag is fragile — callers can forget to check it. The `getOrdValue` wrapper above silently ignores errors! Prefer `Option[T]` or `Result[T, E]`.

---

## 3. Data Model Choices

### 3.1 Object Variants for AST Nodes (The Core Pattern)
**File:** `astdef.nim:534-550`

The entire compiler AST is built on object variants — this is the single most important data structure:

```nim
TNode*{.final, acyclic.} = object
  typField*: PType
  info*: TLineInfo
  flags*: TNodeFlags
  case kind*: TNodeKind
  of nkCharLit..nkUInt64Lit:
    intVal*: BiggestInt
  of nkFloatLit..nkFloat128Lit:
    floatVal*: BiggestFloat
  of nkStrLit..nkTripleStrLit:
    strVal*: string
  of nkSym:
    sym*: PSym
  of nkIdent:
    ident*: PIdent
  else:
    sons*: TNodeSeq
```

Key design decisions:
- `{.final.}` prevents inheritance (object variants and inheritance don't mix well)
- `{.acyclic.}` helps the GC (nodes don't form cycles)
- Common fields (`typField`, `info`, `flags`) are outside the `case`
- The `else` branch captures the most common case (tree nodes with children)

**Verdict: ✅ Good pattern.** Object variants are Nim's sum types. Use `{.final.}` on them. Place shared fields outside the `case`. Use `else` for the largest branch.

### 3.2 Object Variants with Branch-Specific Fields in TSym
**File:** `astdef.nim:625-680`

```nim
TSym* {.acyclic.} = object
  itemId*: ItemId
  state*: ItemState
  case kindImpl*: TSymKind
  of routineKinds:
    gcUnsafetyReasonImpl*: PSym
    transformedBodyImpl*: PNode
  of skLet, skVar, skField, skForVar:
    guardImpl*: PSym
    bitsizeImpl*: int
    alignmentImpl*: int
  else: nil
  magicImpl*: TMagic           # common fields continue after case
  typImpl*: PType
  name*: PIdent
  # ... many more common fields
```

**Verdict: ✅ Good pattern.** Uses `of` with const sets (`routineKinds = {skProc, skFunc, skMethod, skIterator, skConverter, skMacro, skTemplate}`) to share variant branches. Common fields follow the case block. The set-based branch is clean.

### 3.3 Ref Objects Everywhere (PNode, PType, PSym)
**File:** `astdef.nim:532-534`

```nim
PNode* = ref TNode
PType* = ref TType
PSym* = ref TSym
```

The compiler uses the `P` prefix convention for ref types (from Pascal tradition). All core types are `ref` for identity semantics and cheap copying.

**Verdict: ✅ Good pattern for graph-like data.** When your data forms a graph with shared nodes (AST, type graph), `ref` is the right choice. For simple value types, prefer stack-allocated objects.

### 3.4 Tuples for Structured Returns
**File:** `modulegraphs.nim:80-81`

```nim
Operators* = object
  opNot*, opContains*, opLe*, opLt*, opAnd*, opOr*, opIsNil*, opEq*: PSym
  opAdd*, opSub*, opMul*, opDiv*, opLen*: PSym
```

The compiler mostly uses named `object` types rather than anonymous tuples for structured returns, which is clearer.

**Verdict: ✅ Good pattern.** Use named `object` or `tuple` types for multi-field returns. Anonymous tuples are fine for 2-3 fields with obvious meaning.

---

## 4. Accessor Patterns

### 4.1 Virtual Fields via Accessor Procs (Lazy Loading Pattern)
**File:** `ast.nim:55-340`

This is the compiler's most distinctive API pattern. The underlying fields have `Impl` suffixes and are private; public access goes through inline procs that perform lazy loading:

```nim
# Field in TSym (astdef.nim):
kindImpl*: TSymKind

# Public accessor (ast.nim:91-97):
proc kind*(s: PSym): TSymKind {.inline.} =
  if s.state == Partial: loadSym(s)
  result = s.kindImpl

proc `kind=`*(s: PSym, val: TSymKind) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadSym(s)
  s.kindImpl = val
```

This wraps a lazy-loading/caching mechanism behind a clean property-like API. Every field of `TSym` and `TType` follows this pattern.

**Verdict: ✅ Excellent pattern for:**
- Lazy loading (transparent deserialization)
- Validation on write (assertions on state)
- Debugging (breakpoints on field access)
- Future flexibility (can change implementation without breaking callers)

**Caveat:** The boilerplate is significant (~80+ accessor pairs). Consider macros or templates for generating these in your own code.

### 4.2 `incl`/`excl` Overloads for Flag Set Manipulation
**File:** `ast.nim:283-308, 387-398`

```nim
proc incl*(s: PSym; flag: TSymFlag) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadSym(s)
  s.flagsImpl.incl(flag)

proc incl*(s: PSym; flags: set[TSymFlag]) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadSym(s)
  s.flagsImpl.incl(flags)
```

Overloading `incl`/`excl` from the standard library to work with the wrapper type.

**Verdict: ✅ Good pattern.** Extending stdlib operations to your types via overloading is idiomatic Nim. Callers can write `sym.incl sfExported` naturally.

### 4.3 Property-Like Named Accessors for Semantic Queries
**File:** `ast.nim:487-530`

```nim
proc elementType*(n: PType): PType {.inline.} =
  if n.state == Partial: loadType(n)
  n.sonsImpl[^1]

proc baseClass*(n: PType): PType {.inline.} =
  if n.state == Partial: loadType(n)
  n.sonsImpl[0]

proc returnType*(n: PType): PType {.inline.} =
  if n.state == Partial: loadType(n)
  n.sonsImpl[0]
```

These give meaningful names to positional indexing into the `sons` array.

**Verdict: ✅ Good pattern.** Named accessors beat magic index numbers. `t.returnType` is infinitely clearer than `t[0]`.

### 4.4 `template` for Zero-Cost Field Aliases
**File:** `ast.nim:478-485`

```nim
template firstSon*(n: PNode): PNode = n.sons[0]
template secondSon*(n: PNode): PNode = n.sons[1]
template hasSon*(n: PNode): bool = n.len > 0
template has2Sons*(n: PNode): bool = n.len > 1
```

**Verdict: ✅ Good pattern.** Templates for trivial computed properties have zero overhead and keep the API clean.

---

## 5. Parameter Design

### 5.1 Default Parameter Values
**File:** `ast.nim:422` (newSym)

```nim
proc newSym*(symKind: TSymKind, name: PIdent, idgen: IdGenerator; owner: PSym,
             info: TLineInfo; options: TOptions = {}): PSym =
```

**Verdict: ✅ Good pattern.** Default `options: TOptions = {}` is clean — empty set as default for flag-like params.

### 5.2 `sink` Parameters for Ownership Transfer
**File:** `ast.nim:313, 317`

```nim
proc setSnippet*(s: PSym; val: sink string) {.inline.} =
  assert s.state != Sealed
  if s.state == Partial: loadSym(s)
  s.locImpl.snippet = val

proc `sons=`*(t: PType, val: sink TTypeSeq) {.inline.} =
```

**Verdict: ✅ Good pattern.** Using `sink` on setters signals ownership transfer explicitly and can avoid copies.

### 5.3 Overloaded Procs for Different Input Types
**File:** `ast.nim:446-460`

```nim
proc newAtom*(ident: PIdent, info: TLineInfo): PNode
proc newAtom*(kind: TNodeKind, intVal: BiggestInt, info: TLineInfo): PNode
proc newAtom*(kind: TNodeKind, floatVal: BiggestFloat, info: TLineInfo): PNode
proc newAtom*(kind: TNodeKind; strVal: sink string; info: TLineInfo): PNode
```

Multiple `newAtom` overloads for different value types.

**Verdict: ✅ Good pattern.** Name overloading for conceptually identical construction with different inputs. Keeps the API surface small.

### 5.4 `varargs[PNode]` for Flexible Child Lists
**File:** `ast.nim:467-479`

```nim
proc newTree*(kind: TNodeKind; info: TLineInfo; children: varargs[PNode]): PNode =
  result = newNodeI(kind, info)
  if children.len > 0:
    result.info = children[0].info
  result.sons = @children
```

**Verdict: ✅ Good pattern.** `varargs` for builder-style APIs where you pass 0-N children naturally.

### 5.5 Named Constant Sets for Parameter Constraints
**File:** `astdef.nim:406-410`

```nim
const
  routineKinds* = {skProc, skFunc, skMethod, skIterator,
                   skConverter, skMacro, skTemplate}
  ExportableSymKinds* = {skVar, skLet, skConst, skType, skEnumField, skStub} + routineKinds
```

**Verdict: ✅ Good pattern.** Named const sets make case expressions and `in` checks self-documenting.

---

## 6. Public API Boundaries

### 6.1 `export` for Re-Exporting from Aggregator Modules
**File:** `ast.nim:21,24,27`

```nim
export int128
export nodekinds
export astdef
```

`ast.nim` re-exports types from `astdef.nim`, `nodekinds.nim`, and `int128`. Callers only need to `import ast` to get everything.

**Verdict: ✅ Good pattern.** Aggregator modules with `export` reduce import boilerplate. `ast.nim` is the public facade; `astdef.nim` is implementation detail.

### 6.2 Module Splitting: Def vs Accessors
**Files:** `astdef.nim` (data definitions), `ast.nim` (accessors & constructors)

The compiler splits the type definitions (`astdef.nim`) from the accessor procs and constructors (`ast.nim`). This is a deliberate architectural choice:
- `astdef.nim`: ~1100 lines of pure type definitions
- `ast.nim`: ~1700 lines of accessor procs, constructors, iterators

**Verdict: ✅ Good pattern for very large modules.** Separating data declarations from operations makes both easier to navigate. Most codebases don't need this split unless a module exceeds ~2000 lines.

### 6.3 `*` Visibility (Everything Public by Default in Compiler)
**File:** Throughout

The compiler marks virtually everything with `*` (public). There are very few truly private procs. This is a pragmatic choice for a self-contained application.

**Verdict: ⚠️ Appropriate for applications, not libraries.** For library APIs, be selective with `*`. The compiler gets away with this because it's not a library with versioning concerns. Export only what callers need.

### 6.4 Conditional Compilation for Optional Features
**File:** `ast.nim:170-180`, `astdef.nim:699-702`

```nim
when defined(nimsuggest):
  proc endInfo*(s: PSym): TLineInfo {.inline.} =
    # ...

when hasFFI:
  cnameImpl*: string
```

**Verdict: ✅ Good pattern.** Use `when defined(...)` to conditionally include fields/procs. Keeps the core lean while supporting optional features.

---

## 7. Type Hierarchy Design

### 7.1 Flat Enum Hierarchies with Const Groupings
**File:** `astdef.nim:38-122` (TSymFlag — 63 flags!), `astdef.nim:128-230` (TNodeKind)

Rather than deep type hierarchies, the compiler uses large flat enums with const set groupings:

```nim
TSymKind* = enum
  skUnknown, skConditional, skDynLib, skParam, skGenericParam,
  skTemp, skModule, skType, skVar, skLet, skConst, skResult,
  skProc, skFunc, skMethod, skIterator, skConverter, skMacro,
  skTemplate, skField, skEnumField, skForVar, skLabel, skStub, skPackage

const
  routineKinds* = {skProc, skFunc, skMethod, skIterator,
                   skConverter, skMacro, skTemplate}
```

Similarly, `TNodeKind` has ~100+ members grouped via const sets like `nkCallKinds`, `nkLiterals`.

**Verdict: ✅ Good pattern.** Flat enums + named const sets is more Nim-idiomatic than class hierarchies. Pattern matching via `case` works naturally. The const sets act as "subclasses" for `in` checks.

### 7.2 Enum with String Values for Debugging
**File:** `astdef.nim:32-45`

```nim
TCallingConvention* = enum
  ccNimCall = "nimcall"
  ccStdCall = "stdcall"
  ccCDecl = "cdecl"
  ccSafeCall = "safecall"
  ccSysCall = "syscall"
  ccInline = "inline"
  ccNoInline = "noinline"
  ccFastCall = "fastcall"
  ccThisCall = "thiscall"
  ccClosure  = "closure"
  ccNoConvention = "noconv"
  ccMember = "member"
```

**Verdict: ✅ Good pattern.** Assigning string values to enum members gives automatic nice `$` output and is useful for serialization/rendering.

### 7.3 `distinct` Types for Type Safety
**File:** `pathutils.nim:19-22`, `lineinfos.nim:307`, `modulegraphs.nim:28`

```nim
# pathutils.nim
AbsoluteFile* = distinct string
AbsoluteDir* = distinct string
RelativeFile* = distinct string
RelativeDir* = distinct string

# lineinfos.nim
FileIndex* = distinct int32

# modulegraphs.nim
SigHash* = distinct MD5Digest
```

With `{.borrow.}` for delegated operations:

```nim
# pathutils.nim
proc removeFile*(x: AbsoluteFile) {.borrow.}
proc extractFilename*(x: AbsoluteFile): string {.borrow.}
proc fileExists*(x: AbsoluteFile): bool {.borrow.}
```

And type-safe operators:

```nim
proc `/`*(base: AbsoluteDir; f: RelativeFile): AbsoluteFile =
  # Can't accidentally mix AbsoluteDir/AbsoluteFile!
```

**Verdict: ✅ Excellent pattern.** `distinct` types prevent mixing up conceptually different values that share the same underlying type. The pathutils module is a textbook example: you can never accidentally pass an absolute path where a relative one is expected.

### 7.4 Flag Overloading via Const Aliases
**File:** `astdef.nim:225-240`

```nim
const
  sfNoInit* = sfMainModule       # don't generate code to init the variable
  sfNoForward* = sfRegister
  sfReorder* = sfForward
  sfCompileToCpp* = sfInfixCall
  sfCompileToObjc* = sfNamedParamCall
  sfExperimental* = sfOverridden
  sfWrittenTo* = sfBorrow
```

**Verdict: ⚠️ Anti-pattern to avoid in new code.** Aliasing flags to save enum space is a legacy optimization that hurts readability. `sfNoInit` and `sfMainModule` are semantically different but share the same bit. Only acceptable when you're absolutely sure the contexts never overlap (which the compiler ensures via `TSymKind` branching).

---

## 8. Builder / Factory Patterns

### 8.1 Constructor Functions (No Builder Pattern)
**File:** `ast.nim:422-430`, `ast.nim:446-479`

The compiler uses direct constructor functions, not builders:

```nim
proc newSym*(symKind: TSymKind, name: PIdent, idgen: IdGenerator; owner: PSym,
             info: TLineInfo; options: TOptions = {}): PSym =
  let id = nextSymId idgen
  result = PSym(name: name, kindImpl: symKind, flagsImpl: {}, infoImpl: info,
                itemId: id, optionsImpl: options, ownerFieldImpl: owner,
                offsetImpl: defaultOffset,
                disamb: getOrDefault(idgen.disambTable, name).int32)

proc newType*(kind: TTypeKind; idgen: IdGenerator; owner: PSym;
              son: sink PType = nil): PType =
  let id = nextTypeId idgen
  result = PType(kind: kind, ownerFieldImpl: owner, sizeImpl: defaultSize,
                 alignImpl: defaultAlignment, itemId: id,
                 uniqueId: id, sonsImpl: @[])
```

Key design choices:
- Return `ref` objects directly (no separate `init` needed)
- Use named field initialization in the constructor
- Pass an `IdGenerator` for ID allocation (dependency injection)
- `sink` parameter for optional child

**Verdict: ✅ Good pattern.** Nim's named field constructors are cleaner than a Builder class. For complex objects, factory procs with defaults are sufficient.

### 8.2 `linkTo` for Bidirectional Links
**File:** `ast.nim:443-448`

```nim
proc linkTo*(t: PType, s: PSym): PType {.discardable.} =
  t.sym = s
  s.typImpl = t
  result = t

proc linkTo*(s: PSym, t: PType): PSym {.discardable.} =
  t.sym = s
  s.typImpl = t
  result = s
```

**Verdict: ✅ Good pattern.** `linkTo` establishes a bidirectional type↔symbol link and returns the "other" end, with `{.discardable.}`. This is a clean factory helper for graph-like data.

### 8.3 `newProcNode` — Factory with Positional Params
**File:** `ast.nim:498-504`

```nim
proc newProcNode*(kind: TNodeKind, info: TLineInfo, body: PNode,
                 params, name, pattern, genericParams,
                 pragmas, exceptions: PNode): PNode =
  result = newNodeI(kind, info)
  result.sons = @[name, pattern, genericParams, params,
                  pragmas, exceptions, body]
```

**Verdict: ⚠️ Acceptable but could be better.** This uses positional params with many `PNode` params — easy to mix up the order. Could benefit from an object constructor or named params via a config object.

### 8.4 `newConfigRef` — Factory with Explicit Defaults
**File:** `options.nim:716-770`

```nim
proc newConfigRef*(): ConfigRef =
  result = ConfigRef(
    cCompiler: ccGcc,
    macrosToExpand: newStringTable(modeStyleInsensitive),
    arcToExpand: newStringTable(modeStyleInsensitive),
    m: initMsgConfig(),
    # ... 40+ fields with explicit defaults
  )
  initConfigRefCommon(result)
```

Note the split: a `newConfigRef` with all field defaults plus `initConfigRefCommon` for shared initialization logic (used by both `newConfigRef` and `newPartialConfigRef`).

**Verdict: ✅ Good pattern.** Factories with explicit defaults are self-documenting. The shared `init*Common` pattern avoids duplication between full and partial constructors.

---

## 9. Iterator Design

### 9.1 Named Iterators for Traversal Patterns
**File:** `ast.nim:540-590`

```nim
iterator paramTypes*(t: PType): (int, PType) =
  for i in FirstParamAt..<t.len: yield (i, t[i])

iterator paramTypePairs*(a, b: PType): (PType, PType) =
  for i in FirstParamAt..<a.len: yield (a[i], b[i])

iterator genericInstParams*(t: PType): (bool, PType) =
  for i in 1..<t.len-1:
    yield (i!=1, t[i])

iterator kids*(t: PType): PType =
  for i in 0..<t.len: yield t[i]
```

**Verdict: ✅ Good pattern.** Named iterators with specific tuple yields make traversal intent clear. `(bool, PType)` where `bool` means "is first" is a bit unusual but documented by usage.

---

## 10. Template Patterns

### 10.1 Templates for Error-Context Helpers
**File:** `msgs.nim:625-665`

```nim
template fatal*(conf: ConfigRef; info: TLineInfo, arg = "", msg = errFatal) =
  liMessage(conf, info, msg, arg, doAbort, instLoc())

template globalAssert*(conf: ConfigRef; cond: untyped, info: TLineInfo = unknownLineInfo, arg = "") =
  if not cond:
    var arg2 = "'$1' failed" % [astToStr(cond)]
    if arg.len > 0: arg2.add "; " & astToStr(arg) & ": " & arg
    liMessage(conf, info, errGenerated, arg2, doRaise, instLoc())
```

**Verdict: ✅ Good pattern.** Using templates for control-flow-like operations (`fatal`, `globalAssert`) that capture `instLoc()` at the call site. `astToStr` shows the expression in error messages.

### 10.2 Templates for Computed Properties
**File:** `ast.nim:473-476`

```nim
template fileIdx*(c: PSym): FileIndex =
  c.position().FileIndex

template filename*(c: PSym): string =
  c.position().FileIndex.toFilename
```

**Verdict: ✅ Good pattern.** Templates for zero-cost computed properties. No function call overhead.

---

## Summary: Key Recommendations

### Strongly Recommended
1. **`distinct` types** for domain safety (pathutils.nim pattern)
2. **Object variants** with `{.final.}` for sum types (TNode pattern)
3. **Accessor procs** with `{.inline.}` for encapsulation (ast.nim pattern)
4. **`export`** in aggregator modules (ast.nim re-exports astdef)
5. **Named const sets** to group enum values (routineKinds pattern)
6. **Factory procs** with named field init + defaults (newSym, newType pattern)
7. **`sink` params** on setters and constructors for ownership clarity
8. **Explicit calling conventions** on callback proc types
9. **Named iterators** for common traversal patterns

### Use With Caution
1. **Side-channel error reporting** — appropriate for batch processors, not general libraries
2. **`var bool` error flags** — prefer Option/Result
3. **Flag aliasing** — only when absolutely certain of non-overlapping contexts

### Avoid in New Code
1. **Silently ignoring errors** (getOrdValue swallowing var bool)
2. **Positional params** for 7+ same-type parameters (newProcNode)
