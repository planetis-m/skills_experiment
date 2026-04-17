# Test: core_patterns.md reference compiles and works

from std/paths import Path, isAbsolute

# Callable kind: func for pure helpers
func isAbsolutePath(path: Path): bool =
  result = isAbsolute(path)

# Callable kind: template for tiny substitutions
template asString(x): string =
  string(x)

# Calls and result style
proc formatMessage(name: string; count: int;
    urgent: bool; includeFooter: bool): string =
  result = name & ":" & $count & ":" & $urgent & ":" & $includeFooter

proc buildMessage(name: string; count: int; urgent: bool): string =
  result = formatMessage(name, count,
    urgent = urgent,
    includeFooter = true)

# Locals and fields
type
  ParseConfig = object
    maxCount, retryLimit: int
    strict: bool

# Object constructors with defaults
type
  WorkerState = object
    retryLimit: int = 3
    stopRequested: bool
    label: string = "worker"

proc initWorkerState(): WorkerState =
  WorkerState()

proc initNamedWorker(label: string): WorkerState =
  WorkerState(label: label)

proc main =
  # func
  let p = Path("/tmp")
  doAssert isAbsolutePath(p)

  # template
  doAssert asString("hello") == "hello"

  # buildMessage
  doAssert buildMessage("test", 5, true) == "test:5:true:true"

  # locals
  let items = @[10, 20, 30]
  let idx = 1
  let item = items[idx]
  var total = 0
  for i in items:
    total += i
  doAssert item == 20
  doAssert total == 60

  # grouped fields
  let cfg = ParseConfig(maxCount: 100, retryLimit: 5, strict: true)
  doAssert cfg.maxCount == 100
  doAssert cfg.retryLimit == 5

  # object constructor with defaults
  let ws = initWorkerState()
  doAssert ws.retryLimit == 3
  doAssert ws.stopRequested == false
  doAssert ws.label == "worker"

  let named = initNamedWorker("custom")
  doAssert named.label == "custom"
  doAssert named.retryLimit == 3  # default preserved

main()
echo "ref_core_patterns: PASS"
