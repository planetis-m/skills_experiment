## C17: "Use distinct types to prevent accidental mixing of conceptually different
## values. Provide {.borrow.} procs for == and $."

import std/assertions

type
  Port = distinct uint16
  Color = distinct int

proc `==`*(a, b: Port): bool {.borrow.}
proc `$`*(p: Port): string {.borrow.}
proc `==`*(a, b: Color): bool {.borrow.}
proc `$`*(c: Color): string {.borrow.}

block distinct_prevents_mixing:
  proc serve(p: Port): bool = true
  let p = Port(8080)
  doAssert serve(p), "distinct value accepted"
  # A plain uint16 cannot be passed where Port is expected
  doAssert not compiles(serve(uint16(8080))), "distinct prevents implicit conversion"

block borrow_eq_works:
  let a = Port(80)
  let b = Port(80)
  let c = Port(443)
  doAssert a == b, "borrow == works for equal ports"
  doAssert not (a == c), "borrow == works for different ports"

block borrow_dollar_works:
  let p = Port(8080)
  doAssert $p == "8080", "borrow $ works for Port"
  let c = Color(0xff0000)
  doAssert $c == "16711680", "borrow $ works for Color"

block no_implicit_arithmetic:
  let p = Port(80)
  # Distinct types do not inherit arithmetic from base type
  doAssert not compiles(p + Port(1)), "distinct prevents implicit arithmetic"

echo "C17: PASS"
