import std/macros

macro simpleLog(args: varargs[untyped]): untyped =
  result = newCall(newIdentNode("echo"))
  for a in args:
    result.add a

let x = 42
simpleLog("value is: ", x)
