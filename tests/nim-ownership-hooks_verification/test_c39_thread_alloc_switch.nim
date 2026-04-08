# C39: Use compile-time switching for shared payload allocation.
# Run this under both --threads:off and --threads:on.

type Payload = object
  value: int

template allocPayload(): ptr Payload =
  when compileOption("threads"):
    cast[ptr Payload](allocShared0(sizeof(Payload)))
  else:
    cast[ptr Payload](alloc0(sizeof(Payload)))

template freePayload(p: ptr Payload) =
  when compileOption("threads"):
    deallocShared(p)
  else:
    dealloc(p)

proc main() =
  let p = allocPayload()
  doAssert p != nil

  when compileOption("threads"):
    p.value = 39
    doAssert p.value == 39
    echo "C39: PASS threaded"
  else:
    p.value = 39
    doAssert p.value == 39
    echo "C39: PASS single"

  freePayload(p)

main()
