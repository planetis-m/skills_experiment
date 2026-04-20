block:
  var allocs: seq[pointer] = @[]
  for i in 0..<10:
    allocs.add(alloc(64))

  when defined(useMalloc):
    for a in allocs:
      dealloc(a)
    echo "C16: PASS (useMalloc confirmed active)"
  else:
    for a in allocs:
      dealloc(a)
    echo "C16: PASS (default allocator)"
