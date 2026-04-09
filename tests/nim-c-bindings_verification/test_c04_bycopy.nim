# Test C04: bycopy for value structs passed by value
type
  Vec3 {.bycopy.} = object
    x, y, z: cfloat

proc takeVec(v: Vec3): cfloat =
  result = v.x + v.y + v.z

var v = Vec3(x: 1.0'f32, y: 2.0'f32, z: 3.0'f32)
doAssert takeVec(v) == 6.0'f32

echo "C04: PASS"
