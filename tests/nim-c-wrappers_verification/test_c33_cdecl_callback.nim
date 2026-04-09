# Test C33: callback with cdecl
type
  CallbackFn = proc(userdata: pointer; code: cint) {.cdecl.}

proc myCallback(userdata: pointer; code: cint) {.cdecl.} =
  discard

proc setCallback(fn: CallbackFn; userdata: pointer) =
  discard

setCallback(myCallback, nil)

echo "C33: PASS"
