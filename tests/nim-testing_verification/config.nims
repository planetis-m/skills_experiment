switch("path", "$projectdir/../src")
switch("path", "$projectDir")

when defined(addressSanitizer):
  switch("debugger", "native")
  switch("define", "noSignalHandler")
  switch("define", "useMalloc")
  switch("passC", "-fsanitize=address -fno-omit-frame-pointer")
  switch("passL", "-fsanitize=address -fno-omit-frame-pointer")
