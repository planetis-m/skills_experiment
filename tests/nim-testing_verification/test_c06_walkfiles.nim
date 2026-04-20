import std/os

let testDir = getCurrentDir()
var found = 0
for f in walkFiles(testDir / "tauto_*.nim"):
  found += 1
doAssert found == 0, "C06: walkFiles should find no tauto_*.nim files (sanity check)"

echo "C06: PASS"
