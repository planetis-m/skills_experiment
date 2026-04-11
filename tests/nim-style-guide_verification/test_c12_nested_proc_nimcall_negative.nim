## C12: a nested proc marked {.nimcall.} cannot capture outer locals

proc outer() =
  var x = 1

  proc captured() {.nimcall.} =
    inc x

  captured()

outer()
