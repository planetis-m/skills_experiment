type
  MyObj = object
    data: seq[int]

proc makeObj(): MyObj =
  result = MyObj(data: @[1, 2, 3])

proc extractCopy(obj: var MyObj): seq[int] =
  result = obj.data

proc extractMove(obj: var MyObj): seq[int] =
  result = move(obj.data)

proc main() =
  var a = makeObj()
  let b = extractCopy(a)
  echo b
  var c = makeObj()
  let d = extractMove(c)
  echo d

main()
