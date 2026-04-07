# C16 NEGATIVE: Official docs example - generic type used before hooks.
# This SHOULD fail compilation.

type
  Foo[T] = object

proc main =
  var f: Foo[int]
  # error: destructor for 'f' called here before
  # it was seen in this module.

proc `=destroy`[T](f: Foo[T]) =
  discard
