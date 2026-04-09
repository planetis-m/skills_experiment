# Test C34: keep callback state in a global registry keyed by userdata.
import std/tables

type
  CallbackFn = proc(userdata: pointer; code: cint) {.cdecl.}
  CallbackState = ref object
    total: int

var callbackStates {.global.}: Table[pointer, CallbackState]

proc eventBridge(userdata: pointer; code: cint) {.cdecl.} =
  callbackStates[userdata].total += int(code)

proc registerState(state: CallbackState): tuple[cb: CallbackFn, userdata: pointer] =
  let userdata = cast[pointer](callbackStates.len + 1)
  callbackStates[userdata] = state
  result = (eventBridge, userdata)

let state = CallbackState(total: 0)
let registration = registerState(state)
registration.cb(registration.userdata, 7)
registration.cb(registration.userdata, 5)

doAssert callbackStates[registration.userdata] == state
doAssert state.total == 12

echo "C34: PASS"
