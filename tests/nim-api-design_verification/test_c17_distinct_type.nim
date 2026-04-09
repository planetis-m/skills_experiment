## C17: distinct types prevent accidental mixing; {.borrow.} for == and $

type
  Port = distinct uint16
  Color = distinct int

# Borrow == and $ for Port
proc `==`*(a, b: Port): bool {.borrow.}
proc `$`*(p: Port): string {.borrow.}

# Explicit arithmetic for Port (no implicit promotion)
proc `+`*(a, b: Port): Port = Port(uint16(a) + uint16(b))

proc takePort(p: Port) = discard

# --- Test 1: distinct types reject plain base type ---
# This is a compile-time test. We use static assert to confirm distinctness.
doAssert not (Port is uint16), "Port must NOT be the same type as uint16"

# --- Test 2: {.borrow.} == works correctly ---
let p1 = Port(80)
let p2 = Port(80)
let p3 = Port(443)
doAssert p1 == p2, "borrowed == should return true for equal values"
doAssert not (p1 == p3), "borrowed == should return false for different values"

# --- Test 3: {.borrow.} $ works correctly ---
doAssert $p1 == "80", "borrowed $ should stringify the underlying value"
doAssert $p3 == "443", "borrowed $ should stringify the underlying value"

# --- Test 4: explicit arithmetic works ---
let p4 = p1 + Port(10)
doAssert p4 == Port(90), "explicit + proc should work on distinct type"

# --- Test 5: Color is separate from Port (no cross-type mixing) ---
let c = Color(80)
# takePort(c) would fail to compile — confirmed by `not (Color is Port)`
doAssert not (Color is Port), "Color and Port must be distinct from each other"

echo "C17: PASS"
