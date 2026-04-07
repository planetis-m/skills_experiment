# C01: Compiler auto-manages destruction for string, seq, ref, array, tuples, closures, objects with auto-managed fields.
import std/assertions

type AutoObj = object
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
  var r: ref int
  new(r)
  r[] = 42
  var cl = proc(): int = 42
  discard cl()
  x.s = "world"
  x.sq = @[4, 5, 6]
  echo "C01: PASS"
main()
