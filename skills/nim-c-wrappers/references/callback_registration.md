# Callback Registration

Pattern for registering Nim procs as C callbacks with cdecl calling convention.

```nim
type
  LibOnEvent* = proc(userdata: pointer; code: cint) {.cdecl.}

proc libSetOnEvent*(cb: LibOnEvent; userdata: pointer)
  {.importc: "LIB_SetOnEvent", cdecl.}

# Global registry for callback state (avoids GC issues)
var eventHandlers: seq[proc(code: cint)]

proc eventBridge(userdata: pointer; code: cint) {.cdecl.} =
  let idx = cast[int](userdata)
  if idx < eventHandlers.len:
    eventHandlers[idx](code)

proc setOnEvent*(handler: proc(code: cint)) =
  let idx = eventHandlers.len
  eventHandlers.add(handler)
  libSetOnEvent(eventBridge, cast[pointer](idx))
```

## Key points

- Callbacks must be `{.cdecl.}` — C expects a plain function pointer, not a Nim closure.
- Store Nim state in a global table indexed by `userdata`, not in closures.
- Ensure any GC-managed data referenced by callbacks is globally rooted.
