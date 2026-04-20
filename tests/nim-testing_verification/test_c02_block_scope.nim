import testlib

block scope_a:
  let x = 10
  doAssert x == 10

block scope_b:
  let x = 20
  doAssert x == 20

block scope_c:
  var sum = 0
  for i in 1..3:
    sum += i
  doAssert sum == 6

echo "C02: PASS"
