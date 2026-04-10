# API map:
# opaque handle type: BenchffiHandle
# config-bycopy type: BenchffiConfig
# snapshot-bycopy type: BenchffiSnapshot
# status-bycopy type: BenchffiStatus
# ok status constant: BENCHFFI_STATUS_OK
# invalid-argument status constant: BENCHFFI_STATUS_INVALID_ARGUMENT
# open proc: benchffi_open
# close proc: benchffi_close
# push proc: benchffi_push_i32
# snapshot proc: benchffi_snapshot_read
# label proc: benchffi_label
# system math proc: cos

{.push callconv: cdecl, dynlib: "libbenchffi.so".}

type
  BenchffiHandle {.incompleteStruct.} = ptr object
  BenchffiConfig {.bycopy.} = object
    bias: cint
    scale: cuint
    label: cstring
  BenchffiSnapshot {.bycopy.} = object
    count: csize_t
    total: clonglong
    mean: cdouble
    checksum: culong
  BenchffiStatus {.bycopy.} = object
    code: cint
    message: cstring

const
  BENCHFFI_STATUS_OK* = 0
  BENCHFFI_STATUS_INVALID_ARGUMENT* = 1

proc benchffi_open(config: ptr BenchffiConfig): BenchffiHandle {.importc.}
proc benchffi_close(handle: BenchffiHandle) {.importc.}
proc benchffi_push_i32(handle: BenchffiHandle; values: ptr cint; len: csize_t): BenchffiStatus {.importc.}
proc benchffi_snapshot_read(handle: BenchffiHandle): BenchffiSnapshot {.importc.}
proc benchffi_label(handle: BenchffiHandle): cstring {.importc.}

{.pop.}

proc cos(x: cdouble): cdouble {.importc, header: "<math.h>".}

{.passL: "-Wl,-rpath,\\$ORIGIN".}
{.passL: "-lm".}

when isMainModule:
  var config = BenchffiConfig(
    bias: 2,
    scale: 3,
    label: "alpha"
  )
  let handle = benchffi_open(addr config)
  assert handle != nil

  let values = [1.cint, 4.cint, 7.cint]
  let st = benchffi_push_i32(handle, unsafeAddr values[0], 3)
  assert st.code == BENCHFFI_STATUS_OK
  assert $st.message == "ok"

  let snap = benchffi_snapshot_read(handle)
  assert snap.count == 3
  assert snap.total == 54
  assert abs(snap.mean - 18.0) < 1e-12
  assert snap.checksum == 156834

  assert $benchffi_label(handle) == "alpha"

  assert abs(cos(0.0) - 1.0) < 1e-12

  benchffi_close(handle)
  echo "SMOKE: PASS"
