# C11: Typed error enums for structured pipeline results.

type
  PageErrorKind = enum
    NoError, PdfError, EncodeError, NetworkError

  PageResult = object
    page: int
    errorKind: PageErrorKind
    errorMessage: string

proc classifyAndRecord(page: int; errorMsg: string; errorKind: PageErrorKind): PageResult =
  PageResult(page: page, errorKind: errorKind, errorMessage: errorMsg)

proc test() =
  let r1 = classifyAndRecord(1, "pdf failed", PdfError)
  doAssert r1.page == 1
  doAssert r1.errorKind == PdfError
  doAssert r1.errorMessage == "pdf failed"

  let r2 = classifyAndRecord(2, "encode failed", EncodeError)
  doAssert r2.errorKind == EncodeError

  # Structured results can be inspected by callers
  doAssert r1.errorKind != r2.errorKind

test()
echo "C11_enum: PASS"
