proc main() =
  var p = alloc(4 * sizeof(int))
  var arr = cast[ptr UncheckedArray[int]](p)
  arr[0] = 10
  arr[1] = 20
  arr[2] = 30
  arr[3] = 40
  let val = arr[4]
  echo "val: ", val
  dealloc(p)

main()
