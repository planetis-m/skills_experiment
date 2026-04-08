## C12: "An accessor that silently returns a default value (e.g. empty string)
## when data is missing is incorrect; it should raise an error instead."

import std/assertions
import std/strutils

type
  Lookup = object
    data: seq[(string, string)]

# Anti-pattern: silently returns empty string when key not found
proc getSilent(l: Lookup; key: string): string =
  for (k, v) in l.data:
    if k == key:
      return v
  return ""  # silently returns default — hides the problem

# Correct: raises ValueError when key not found
proc getRaise(l: Lookup; key: string): string =
  for (k, v) in l.data:
    if k == key:
      return v
  raise newException(ValueError, "key not found: " & key)

block silent_default_hides_errors:
  let l = Lookup(data: @[("name", "Alice"), ("age", "30")])

  # Existing key works fine
  doAssert getSilent(l, "name") == "Alice"

  # Missing key returns empty string — indistinguishable from a legitimate
  # empty value! The caller cannot tell if "email" is missing or if it was
  # explicitly set to ""
  let result = getSilent(l, "email")
  doAssert result == "", "silent default returns empty string for missing key"

  # This is the bug: caller processes "" as if it were valid data
  # Downstream code might do:
  let emailLen = getSilent(l, "email").len
  doAssert emailLen == 0  # "looks like email is empty" — no, email is MISSING

block raising_correctly_surfaces_problem:
  let l = Lookup(data: @[("name", "Alice"), ("age", "30")])

  # Existing key works fine
  doAssert getRaise(l, "name") == "Alice"

  # Missing key raises ValueError — caller must handle it
  var caught = false
  try:
    discard getRaise(l, "email")
  except ValueError:
    caught = true
    doAssert contains(getCurrentExceptionMsg(), "key not found")
  doAssert caught, "ValueError should be raised for missing key"

block silent_default_causes_downstream_bugs:
  ## Demonstrate that silent defaults can cause real bugs downstream.
  ## Example: formatting a user profile where missing "role" silently
  ## becomes "" and downstream code treats it as valid.
  let l = Lookup(data: @[("name", "Bob")])

  # Silent accessor returns "" for missing "role"
  let role = getSilent(l, "role")
  # Downstream code treats "" as a valid role:
  let isAdmin = role == "admin"
  let isGuest = role == "guest"
  let label = if isAdmin: "Administrator"
              elif isGuest: "Guest"
              else: "Unknown role: " & role  # Shows "Unknown role: "

  doAssert label == "Unknown role: ", "silent default caused confusing output"
  ## The "" was treated as a legitimate role value, producing confusing output.
  ## With the raising version, the caller would be forced to handle the
  ## missing key explicitly.

echo "C12: PASS"
