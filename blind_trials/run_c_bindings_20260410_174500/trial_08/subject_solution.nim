{.passL: "-Lblind_trials/c_bindings_fixture/build -lbenchffi".}
{.passL: "-Wl,-rpath,\\$ORIGIN".}
{.passL: "-lm".}

type
  BenchHandleObj = object
  BenchHandle* = ptr BenchHandleObj

  BenchConfig* {.bycopy.} = object
    bias*: cint
    scale*: cuint
    label*: cstring

  BenchSnapshot* {.bycopy.} = object
    count*: csize_t
    total*: clonglong
    mean*: cdouble
    checksum*: culong

  BenchStatus* {.bycopy.} = object
    code*: cint
    message*: cstring

const
  BENCHFFI_STATUS_OK* = 0.cint
  BENCHFFI_STATUS_INVALID_ARGUMENT* = 1.cint

{.push callconv: cdecl, header: "benchffi.h".}
proc benchffi_open*(config: ptr BenchConfig): BenchHandle {.importc.}
proc benchffi_close*(handle: BenchHandle) {.importc.}
proc benchffi_push_i32*(handle: BenchHandle; values: ptr cint; len: csize_t): BenchStatus {.importc.}
proc benchffi_snapshot_read*(handle: BenchHandle): BenchSnapshot {.importc.}
proc benchffi_label*(handle: BenchHandle): cstring {.importc.}
{.pop.}

proc c_cos*(x: cdouble): cdouble {.importc: "cos", header: "<math.h>", cdecl.}

when isMainModule:
  var config = BenchConfig(
    bias: 2,
    scale: 3,
    label: "alpha"
  )
  let handle = benchffi_open(addr config)
  assert handle != nil

  let values = [1.cint, 4.cint, 7.cint]
  let pushStatus = benchffi_push_i32(handle, unsafeAddr values[0], 3)
  assert pushStatus.code == BENCHFFI_STATUS_OK
  assert $pushStatus.message == "ok"

  let snap = benchffi_snapshot_read(handle)
  assert snap.count == 3
  assert snap.total == 54
  assert abs(snap.mean - 18.0) < 1e-12
  assert snap.checksum == 156834

  assert $benchffi_label(handle) == "alpha"
  assert abs(c_cos(0.0) - 1.0) < 1e-12

  benchffi_close(handle)
  echo "SMOKE: PASS"
