# Test C33: Zero-length allocation guards in constructors.
# alloc(0) may return nil or an invalid pointer; accessing data[0] on
# a zero-length allocation causes index-out-of-bounds.

import std/strutils

type
  MyString = object
    data: ptr char
    len: int

proc `=destroy`*(x: MyString) =
  if x.data != nil:
    dealloc(x.data)

proc `=wasMoved`*(x: var MyString) =
  x.data = nil
  x.len = 0

proc `=dup`*(x: MyString): MyString {.nodestroy.} =
  result = MyString(len: x.len, data: nil)
  if x.data != nil and x.len > 0:
    result.data = cast[ptr char](alloc(x.len + 1))
    copyMem(result.data, x.data, x.len + 1)

proc `=copy`*(dest: var MyString; src: MyString) =
  if dest.data == src.data: return
  `=destroy`(dest)
  `=wasMoved`(dest)
  dest.len = src.len
  if src.data != nil and src.len > 0:
    dest.data = cast[ptr char](alloc(src.len + 1))
    copyMem(dest.data, src.data, src.len + 1)

proc initMyString(s: string): MyString =
  result = MyString(len: s.len, data: nil)
  if s.len > 0:
    result.data = cast[ptr char](alloc(s.len + 1))
    copyMem(result.data, unsafeAddr s[0], s.len + 1)

proc test() =
  # Empty string must not crash
  var a = initMyString("")
  doAssert a.data == nil
  doAssert a.len == 0

  # Non-empty string works normally
  var b = initMyString("hello")
  doAssert b.data != nil
  doAssert b.len == 5

  # Copy of empty string must not crash
  var c = a
  doAssert c.data == nil
  doAssert c.len == 0

  # Dup of empty string
  var d = `=dup`(a)
  doAssert d.data == nil
  doAssert d.len == 0

  echo "C33: PASS"

test()
