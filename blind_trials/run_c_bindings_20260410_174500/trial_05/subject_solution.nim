{.passC: "-Iblind_trials/c_bindings_fixture".}
{.passL: "-Lblind_trials/c_bindings_fixture/build -lbenchffi".}
{.passL: "-Wl,-rpath,\\$ORIGIN".}
{.passL: "-lm".}

type
  BenchHandleObj {.importc: "benchffi_handle", incompleteStruct.} = object
  BenchHandle* = ptr BenchHandleObj

  BenchConfig* {.importc: "benchffi_config", bycopy.} = object
    bias*: cint
    scale*: cuint
    label*: cstring

  BenchSnapshot* {.importc: "benchffi_snapshot", bycopy.} = object
    count*: csize_t
    total*: clonglong
    mean*: cdouble
    checksum*: culong

  BenchStatus* {.importc: "benchffi_status", bycopy.} = object
    code*: cint
    message*: cstring

const
  BENCHFFI_STATUS_OK* = 0.cint
  BENCHFFI_STATUS_INVALID_ARGUMENT* = 1.cint

{.push importc, cdecl, header: "benchffi.h".}
proc benchffi_open*(config: ptr BenchConfig): BenchHandle
proc benchffi_close*(handle: BenchHandle)
proc benchffi_push_i32*(handle: BenchHandle; values: ptr cint; len: csize_t): BenchStatus
proc benchffi_snapshot_read*(handle: BenchHandle): BenchSnapshot
proc benchffi_label*(handle: BenchHandle): cstring
{.pop.}

proc c_cos*(x: cdouble): cdouble {.importc: "cos", cdecl, header: "<math.h>".}

when isMainModule:
  var config = BenchConfig(
    bias: 2,
    scale: 3,
    label: "alpha"
  )
  let handle = benchffi_open(addr config)
  assert handle != nil

  let values = [1.cint, 4.cint, 7.cint]
  let pushResult = benchffi_push_i32(handle, unsafeAddr values[0], 3)
  assert pushResult.code == BENCHFFI_STATUS_OK
  assert $pushResult.message == "ok"

  let snap = benchffi_snapshot_read(handle)
  assert snap.count == 3
  assert snap.total == 54
  assert abs(snap.mean - 18.0) < 1e-12
  assert snap.checksum == 156834
  assert $benchffi_label(handle) == "alpha"
  assert abs(c_cos(0.0) - 1.0) < 1e-12

  benchffi_close(handle)
  echo "SMOKE: PASS"
