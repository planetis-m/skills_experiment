# Test: callback_pattern.md reference compiles and works
# Standalone — no external C library needed

type
  WriteCallback = proc(buffer: ptr char, size: csize_t, nitems: csize_t,
    userdata: pointer): csize_t {.cdecl.}

proc bodyWriteCb(buffer: ptr char, size: csize_t, nitems: csize_t,
    userdata: pointer): csize_t {.cdecl.} =
  let total = int(size * nitems)
  if total <= 0:
    result = 0
  else:
    let body = cast[ptr string](userdata)
    if body.isNil:
      result = csize_t(total)
    else:
      let start = body[].len
      body[].setLen(start + total)
      copyMem(addr body[][start], buffer, total)
      result = csize_t(total)

proc main =
  # Test callback with real data
  var output = ""
  var data = "hello"
  let written = bodyWriteCb(addr data[0], csize_t(1), csize_t(5), addr output)
  doAssert written == 5
  doAssert output == "hello"

  # Test callback with nil userdata
  let written2 = bodyWriteCb(addr data[0], csize_t(1), csize_t(3), nil)
  doAssert written2 == 3

  # Test callback with zero size
  let written3 = bodyWriteCb(addr data[0], csize_t(0), csize_t(0), addr output)
  doAssert written3 == 0

  # Verify the callback type can be passed as a variable
  var cb: WriteCallback = bodyWriteCb
  doAssert cb(addr data[0], csize_t(1), csize_t(2), addr output) == 2
main()

echo "ref_callback_pattern: PASS"
