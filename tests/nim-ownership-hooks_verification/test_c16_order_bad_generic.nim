# C16: Hook declaration order. Generics used before hooks defined trigger compiler error.
type Foo[T] = object

proc main =
  var f: Foo[int]

proc `=destroy`[T](f: Foo[T]) = discard
