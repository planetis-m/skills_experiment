# Shared / refcounted handle

Two conventions exist for the counter.

## Standard counter (counter=1 → exclusive, >1 → shared)

```nim
type
  Payload = object
    counter: int
    value: int

  Handle = object
    p: ptr Payload

proc `=destroy`*(x: Handle) =
  if x.p != nil:
    dec x.p.counter
    if x.p.counter == 0:
      dealloc(x.p)

proc `=wasMoved`*(x: var Handle) =
  x.p = nil

proc `=dup`*(b: Handle): Handle {.nodestroy.} =
  result.p = b.p
  if b.p != nil: inc b.p.counter

proc `=copy`*(a: var Handle; b: Handle) =
  if a.p == b.p: return
  `=destroy`(a)
  `=wasMoved`(a)
  a.p = b.p
  if b.p != nil: inc b.p.counter
```

## Inverted counter (counter=0 → exclusive, >0 → shared)

Used in Nim's standard library (cowstrings). Deep copies set counter=0, sharing increments.

```nim
proc `=destroy`*(x: String) =
  if x.p != nil:
    if x.p.counter == 0:
      dealloc(x.p)     # exclusively owned, free directly
    else:
      dec x.p.counter   # shared, just decrement

proc `=wasMoved`*(x: var String) =
  x.p = nil

proc `=dup`*(b: String): String =
  # No {.nodestroy.} — refcount balances the implicit destroy
  if b.p != nil: inc b.p.counter
  result.p = b.p
  result.len = b.len

proc `=copy`*(a: var String; b: String) =
  # No self-assign guard needed — destroy+share balances via counter
  `=destroy`(a)
  if b.p != nil: inc b.p.counter
  a.p = b.p
  a.len = b.len
```

Key difference: with the inverted counter, `=dup` and `=copy` don't need `{.nodestroy.}` or self-assignment guards because the refcount arithmetic balances the implicit operations.
