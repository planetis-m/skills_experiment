## C01, C02, C07: Object constructors may omit fields, field defaults apply,
## and plain field-by-field mutation does not preserve declaration defaults
## unless the value is initialized from a constructor first.

type
  WorkerState = object
    active: seq[string]
    retryLimit: int = 3
    stopRequested: bool
    label: string = "worker"

proc buildWithConstructor(): WorkerState =
  WorkerState(active: @["a", "b"])

proc buildWithFieldMutationOnly(): WorkerState =
  var state: WorkerState
  state.active = @["a", "b"]
  state

proc buildWithInitializedValueThenMutation(): WorkerState =
  var state = WorkerState()
  state.active = @["a", "b"]
  state

block omitted_fields_are_initialized:
  let state = buildWithConstructor()
  doAssert state.active == @["a", "b"]
  doAssert state.retryLimit == 3
  doAssert state.stopRequested == false
  doAssert state.label == "worker"

block plain_constructor_without_overrides_uses_defaults:
  let state = WorkerState()
  doAssert state.active == @[]
  doAssert state.retryLimit == 3
  doAssert state.stopRequested == false
  doAssert state.label == "worker"

block plain_field_assignment_skips_declaration_defaults:
  let state = buildWithFieldMutationOnly()
  doAssert state.active == @["a", "b"]
  doAssert state.retryLimit == 0
  doAssert state.stopRequested == false
  doAssert state.label == ""

block constructor_then_assignment_preserves_defaults:
  doAssert buildWithConstructor() == buildWithInitializedValueThenMutation()

echo "C01_C02_C07: PASS"
