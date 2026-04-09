# Test C10: reserved keyword renaming (type→typ, addr→address)
proc setName(typ: cint; address: pointer): cint =
  discard typ
  discard address
  result = 0

discard setName(42, nil)

echo "C10: PASS"
