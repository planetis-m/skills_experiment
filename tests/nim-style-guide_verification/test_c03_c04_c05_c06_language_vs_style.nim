## C03, C04, C05, C06: These patterns are legal Nim even when a style guide bans them.

proc localTypeIsLegal(): int =
  type
    LocalCounter = object
      value: int

  let counter = LocalCounter(value: 7)
  result = counter.value

template helperWithControlFlow(values: openArray[int]): int =
  block:
    var total = 0
    for value in values:
      if value > 0:
        total.inc value
    total

proc continueIsLegal(values: openArray[int]): int =
  for value in values:
    if value < 0:
      continue
    result.inc value

proc earlyReturnIsLegal(totalPages: int): seq[int] =
  if totalPages <= 0:
    return @[]
  for page in 1 .. totalPages:
    result.add page

block local_type_block_compiles:
  doAssert localTypeIsLegal() == 7

block template_with_control_flow_compiles:
  doAssert helperWithControlFlow([1, -1, 3, 0]) == 4

block continue_statement_compiles:
  doAssert continueIsLegal([1, -1, 3, -2, 5]) == 9

block early_return_compiles:
  doAssert earlyReturnIsLegal(0) == @[]
  doAssert earlyReturnIsLegal(3) == @[1, 2, 3]

echo "C03_C04_C05_C06: PASS"
