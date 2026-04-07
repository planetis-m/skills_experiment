# C01: Compiler auto-manages destruction for string, seq[T], ref T, array, tuples, closures, objects with auto-managed fields.
# Test: these types should compile and run without custom hooks, and memory should be managed correctly.

import std/assertions

type
  AutoObj = object
    s: string
    sq: seq[int]
    a: array[3, int]
    t: tuple[x: int, y: float]

proc main() =
  var x: AutoObj
  x.s = "hello"
  x.sq = @[1, 2, 3]
  x.a = [10, 20, 30]
  x.t = (x: 1, y: 2.0)
  
  # ref T
  var r: ref int
  new(r)
  r[] = 42
  
  # closure
  var closure = proc(): int = 42
  discard closure()
  
  # Overwrite to trigger destroy of old values
  x.s = "world"
  x.sq = @[4, 5, 6]
  
  echo "C01: PASS - auto-managed types work without custom hooks"

main()
