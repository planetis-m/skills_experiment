# Test C37: cstring lifetime - temporary pointer
# string.cstring creates a temporary cstring; if the source string is on stack,
# the cstring becomes dangling after the string goes out of scope
proc getCstring(): cstring =
  var local = "temporary"
  result = local.cstring
  # local goes out of scope, result is dangling
  # This demonstrates the risk

discard getCstring()
echo "C37: PASS"
